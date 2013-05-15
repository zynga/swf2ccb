task :default => :compile

FLEX_SDK_HOME = ENV['FLEX_SDK_HOME'] || '"/var/lib/flex4sdk"'
if( !FLEX_SDK_HOME )
  abort "Please make sure that you have the FLEX_SDK_HOME environment variable set"
end
COMPC = "#{FLEX_SDK_HOME}/bin/compc"
ASDOC = "#{FLEX_SDK_HOME}/bin/asdoc"


#set the home directory to the location of the rakefile
HOME_DIR = File.dirname(__FILE__)
LIBDIR = "#{HOME_DIR}/lib"
SRCDIR = "#{HOME_DIR}/src"
TARGET = "#{HOME_DIR}/bin/Starling.swc"


srcfiles = Dir.glob("#{SRCDIR}/**/*.as")
#convert the file names to class names
classes = []
srcfiles.each do |src|
  classes << src.gsub(SRCDIR+"/",'').gsub('/', '.').gsub('.as', '')
end

#libs for this project
libs = Dir.glob("#{LIBDIR}/*.swc")

#check to see if any source or library files have been modified
build_required = false
files_to_check = libs + srcfiles
files_to_check << __FILE__
target_mtime = File.exist?(TARGET) ? File.mtime(TARGET) : Time.at(0)
files_to_check.each do |f|
  if(File.mtime(f) > target_mtime)
    build_required = true
    break
  end
end


release_mode = false
task :release do
  release_mode = true
  
  #call the compile task now that we have set release mode
  Rake::Task[:compile].execute
end


task :compile do
  if( build_required )
    opts = []

    if( !release_mode )
      puts "BUILDING IN DEBUG MODE"
      opts << "-debug=true"
      TARGET.sub!(/\.swc/, '.debug.swc')
      opts << "-define=CONFIG::DEBUG,true"
      opts << "-define=CONFIG::RELEASE,false"
      
      #redefine libs for debug mode
	  libs = Dir.glob("#{LIBDIR}/*.swc")
    else
      puts "BUILDING IN RELEASE MODE"
      opts << "-debug=false"
      opts << "-define=CONFIG::DEBUG,false"
      opts << "-define=CONFIG::RELEASE,true"
    end

    opts << "-compute-digest=false"
    opts << "-source-path #{SRCDIR}"
    opts << "-output #{TARGET}"
    opts << "-headless-server=true"

    libs.each do |l|  opts << "-library-path+=#{l}" end

    opts << "-include-classes " + classes.join(' ')

    puts "Compiling to target #{TARGET}..."
    cmd = COMPC + " " + opts.join(" ")
    puts cmd
    sh cmd
  else
    puts "Skipping compilation of #{TARGET} since no files have been modified"
  end
end


task :doc do
  if( build_required )
    puts "Creating docs..."

    opts = []
    opts << "-output #{HOME_DIR}/asdoc-output"
    opts << "-source-path #{SRCDIR}"
    opts << "-doc-sources #{SRCDIR}"

    libs.each do |l|  opts << "-library-path+=#{l}" end

    cmd = ASDOC + " " + opts.join(" ")
    puts cmd
    sh cmd
  else
    puts "Skpping creation of docs since no files have been modified"
  end
end
