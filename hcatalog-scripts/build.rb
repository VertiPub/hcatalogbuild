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

=end

require 'optparse'

class ParseOptions < Hash
  def initialize(args)
    super()
    self[:externalversion] = ''
    self[:branchortag] = ''
    self[:subrepo] = ''

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
  end
end

# Begin with arguments
arguments = ParseOptions.new(ARGV)
# BUG: add a test to confirm definition of WORKSPACE
workSpace = ENV['WORKSPACE]'

# Build the Date String for the "build string"

buildTime = Time.now
buildString = buildTime.strftime("%Y%m%d%H%M")

# Save the starting directory to return to
startingDir = Dir.pwd

# Move to the workspace defined by hudson and initialize/update the repos
Dir.chdir(workSpace)
system "git submodule init"
system "git submodule update"

# Check out the correct branch of code in preparation to call the build
buildDir = workSpace + "/" + arguments[:submodule]
Dir.chdir(buildDir)
branchName = "tobebuilt-" + buildString
command = "git checkout -b " + branchName + " " + arguments[:branchortag]

# Return to the workspace and prepare 2 directories, one for the RPM(s) being generated
# and the other for the file system used to emulate the installed root
installDir = workSpace + "/install-" + buildString
rpmDir = workSpace + "/rpms-" + buildString
Dir.mkdir (rpmDir, "0755") 

