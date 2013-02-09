#!/usr/bin/env ruby
=begin
This is an command to automate the build of the hcatalog project from source.
It assumes a wrapper git repository with a submodule of the actual project to be built.
It's a first attempt make this more modular so it can be refactored to also be used to 
build other projects via a shared common script.

Assumptions:

	1.  WORKSPACE is defined, either via execution within Jenkins or by the user
	2.  The "wrapper" repository has been cloned and the version checked out for use.
        3.  The "wrapper" repository exists at the level of WORKSPACE (ala Jenkins)
        4.  The build script will generate the necessary artifacts to be used by the install script
            a.  The build script will be passed an "ARTIFACT_VERSION" environment variable
            b.  The build script will be passed the "DATE_STRING" environment variable should it need it
            c.  The build script will inherit the "WORKSPACE"  environment variable
            d.  The build script will execute in the submodule directory
            e.  The build script will have a non-zero exit if the build fails for any reason
        5.  The install script will generate the proper build root when passed the correct install directory, and build the RPM
            a.  The build script will be passed an "ARTIFACT_VERSION" environment variable
            b.  The build script will be passed the "DATE_STRING" environment variable should it need it
            c.  The build script will be passed the "INSTALL_DIR" into which to unpack the artifacts created by the build script
            d.  The build script will be passed the "RPM_DIR" into which to place the built RPM
            e.  The build script will inherit the "WORKSPACE"  environment variable
            f.  The build will pass in a description in a single quoted string in the "DESCRIPTION" env variable
        6.  If the JOB_URL is defined it will be included in the Description, otherwise a snide comment will be included
=end

require 'optparse'

class ParseOptions < Hash
  def initialize(args)
    super()
    self[:externalversion] = ''
    self[:branchortag] = ''
    self[:subrepo] = ''
    self[:compilescript] = ''
    self[:installscript] = ''

    # define the opts and usage
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #$0 [options]"
      opts.on('-e', '--externalversion VERSION', 'Numeric dot separated string representing the external project like 0.4.0') do |string|
        self[:externalversion] = string
      end
      opts.on('-b', '--branchortag DESCRIPTION',
              'A Tag, Branch or SHA to define what should be checked out from the subproject to build') do |string|
        self[:branchortag] = string
      end
      opts.on('-s', '--submodule DIRECTORY',
              'The directory containing the sub-repository relative to the build root') do |string|
        self[:submodule] = string
      end
      opts.on('-c', '--compilescript SCRIPTNAME',
              'The bash script that runs the actual compile commands from the submodule directory') do |string|
        self[:compilescript] = string
      end
      opts.on('-i', '--installscript SCRIPTNAME',
              'The bash script that runs the actual install commands to put files into the rpm generation directory') do |string|
        self[:installscript] = string
      end
      opts.on_tail('-h', '--help', 'display this help and exit') do
        puts opts
        exit
      end
    end

    # throw a fit on invalid options and reply with usage
    begin opts.parse! args
    rescue OptionParser::InvalidOption => e
      puts e
      puts opts
      exit 1
    end

    opts.parse!(args)
    # check sanity
    if (self[:externalversion] == '')
      puts opts
      raise "FATAL: You must specify the external project version."
    end
    if (self[:branchortag] == '')
      puts opts
      raise "FATAL: You must specify a branch, tag or SHA in the submodule to sync for the build"
    end
    if (self[:submodule] == '')
      puts opts
      raise "FATAL: You must specify the submodule directory to build, relative to the build root"
    end
    if (self[:compilescript] == '')
      puts opts
      raise "FATAL: You must specify the path to the compile script relative to the build root"
    end
    if (self[:installscript] == '')
      puts opts
      raise "FATAL: You must specify the path to the install script relative to the build root"
    end
  end
end

def allocateDir(dirPath)
  if File.exist?(dirPath) && !File.directory?(dirPath)
    raise "FATAL: unexepected file found at " + dirPath
  elsif !File.directory?(dirPath) 
    Dir.mkdir(dirPath, 0755) 
  end
end

# Begin with arguments
arguments = ParseOptions.new(ARGV)
if ENV['WORKSPACE'].nil?
  raise "FATAL: WORKSPACE environment variable undefined, perhaps you should set it?"
end
workSpace = ENV['WORKSPACE']
if ENV['JOB_URL'].nil?
  jobURL = "This build was hand crafted lovingly and without Jenkins"
else
  jobURL = ENV['JOB_URL']
end

# Build the Date String for the "build string"

buildTime = Time.now
buildString = buildTime.strftime("%Y%m%d%H%M")

# Save the starting directory to return to
startingDir = Dir.pwd

# Move to the workspace defined by hudson and initialize/update the submodule repo
Dir.chdir(workSpace)
system "rm -rf ./install-* ./rpms-*"
system "git submodule init"
system "git submodule update"
gitRepoSHA = %x[git rev-parse HEAD]
gitRepoOrigin = %x[git remote -v | grep fetch |  awk '{print $2}']
rpmDescription = "Built under: #{jobURL} From repository: #{gitRepoOrigin} From SHA: #{gitRepoSHA}"

# Check out the correct branch of code in preparation to call the build
buildDir = workSpace + "/" + arguments[:submodule]
Dir.chdir(buildDir)
branchName = "tobebuilt-" + buildString
command = "git checkout -b " + branchName + " " + arguments[:branchortag]
system command

# Return to the workspace and prepare 2 directories, one for the RPM(s) being generated
# and the other for the file system used to emulate the installed root
installDir = workSpace + "/install-" + buildString
rpmDir = workSpace + "/rpms-" + buildString
allocateDir(installDir)
allocateDir(rpmDir)

# Ok, time to call out to the actual build command
# BUG: At this point the generated artifact isn't being passed. It's implicitly shared between build & install.
# BUG: This is a *bad* *thing*
# Set up the environement
ENV['ARTIFACT_VERSION'] = arguments[:externalversion]
ENV['DATE_STRING'] = buildString
# Run the build
scriptFullPath = workSpace + "/" + arguments[:compilescript]
buildCommand = "/bin/sh -ex " + scriptFullPath
system buildCommand

# Run the install dir create
ENV['INSTALL_DIR'] = installDir
ENV['RPM_DIR'] = rpmDir
ENV['DESCRIPTION'] = rpmDescription
scriptFullPath = workSpace + "/" + arguments[:installscript]
buildCommand = "/bin/sh -ex " + scriptFullPath
system buildCommand
