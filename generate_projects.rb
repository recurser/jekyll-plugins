# Jekyll project page generator.
# http://recursive-design.com/projects/jekyll-plugins/
#
# Version: 0.1.4 (201101061053)
#
# Copyright (c) 2010 Dave Perrett, http://recursive-design.com/
# Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)
#
# Generator that creates project pages for jekyll sites from git repositories. 
#
# This was inspired by the project pages on GitHub, which use the project README file as the index 
# page. It takes git repositories, and automatically builds project pages for them using the README 
# file, along with downloadable zipped copies of the projects themselves (for example, the project 
# page for this "plugin repository":http://recursive-design.com/projects/jekyll-plugins/ is 
# auto-generated with this plugin).
#
# To use it, simply drop this script into the _plugins directory of your Jekyll site. Next, create a 
# *_projects* folder in the base of your jekyll site. This folder should contain .yml files describing 
# how to build a page for your project. Here is an example jekyll-plugins.yml (note: you should remove 
# the leading '# ' characters):
#
# ================================== COPY BELOW THIS LINE ==================================
# layout:     default
# title:      Jekyll Plugins
# repository: git://recursive-design.com/jekyll-plugins.git
# published:  true
# ================================== COPY ABOVE THIS LINE ==================================
#
# When you compile your jekyll site, the plugin will download the git repository of each project
# in your _projects folder, create an index page from the README (using the specified layout),
# and create a downloadable .zip file of the project. The goal is to automate the construction of
# online project pages, keep them in sync with README documentation, and provide an up-to-date zip
# archive for download.
#
# Required files :
# Your project's git repository should contain:
# - README:       The contents of this will be used as the body of your project page will be created 
#                 from. Any extension other than .markdown, .textile or .html will be treated as a 
#                 .textile file.
# - versions.txt: Contains the version string (eg 1.0.0). Used when naming the downloadable zip-file 
#                 (optional). If the version.txt file is not available, a YYYYMMDDHHMM timestamp will 
#                 be used for the version.
#
# Required gems :
# - git     (>= 1.2.5)
# - rubyzip (>= 0.9.4)
#
# Available _config.yml settings :
# - project_dir: The subfolder to compile projects to (default is 'projects').
#
# Available YAML settings :
# - repository: Git repository of your project (required).
# - layout: Layout to use when creating the project page.
# - title: Project title, which can be accessed in the layout.
# - published: Project won't be published if this is false.

require 'fileutils'
require 'find'
require 'git'
require 'zip/zip'
require 'zip/zipfilesystem'
	
module Jekyll  
  
  # The ProjectIndex class creates a single project page for the specified project.
  class ProjectIndex < Page
    
    # Initialize a new ProjectIndex.
    #  +base_dir+            is the String path to the <source>
    #  +project_dir+         is the relative path from the base directory to the project folder.
    #  +project_config_path+ is the String path to the project's yaml config file.
    #  +project_name+        is the name of the project to process.
    def initialize(site, base_dir, project_dir, project_config_path, project_name)
      @site = site
      @base = base_dir
      @dir  = project_dir
      
      self.data = load_config(base_dir, project_config_path)
      
      # Ignore the project unless it has been marked as published.
      unless self.data['published']
        return false
      end
      
      # Clone the repo locally and get the path.
      repo_dir = clone_repo(project_name)
      
      # Get the version if possible.
      version = get_version(repo_dir)
      
      # Create the .zip file.
      self.data['download_link'] = create_zip(repo_dir, project_name, project_dir, version)
      
      # Get the path to the README
      readme = get_readme_path(repo_dir)
      
      # Decide the extension - if it's not textile, markdown or HTML treat it as textile.
      ext = File.extname(readme)
      unless ['.textile', '.markdown', '.html'].include?(ext)
        ext = '.textile'
      end
      
      # Try to get the readme data for this path.
      self.content = File.read(readme)
      
      @name = "index#{ext}"
      self.process(@name)
    end
    
    private
    
    # Loads the .yml config file for this project.
    #
    #  +base_dir+            is the base path to the jekyll project.
    #  +project_config_path+ is the String path to the project's yaml config file.
    #
    # Returns Array of project config information.
    def load_config(base_dir, project_config_path)
      yaml = File.read(File.join(base_dir, project_config_path))
      YAML.load(yaml)
    end
    
    # Clones the project's repository to a temp folder.
    #
    #  +project_name+ is the name of the project to process.
    #
    # Returns String path to the cloned repository.
    def clone_repo(project_name)
      # Make the base clone directory if necessary.
      clone_dir = File.join(Dir.tmpdir(), 'checkout')
      unless File.directory?(clone_dir)
        p = Pathname.new(clone_dir)
        p.mkdir
      end
      
      # Remove any old repo at this location.
      repo_dir = File.join(clone_dir, project_name)
      if File.directory?(repo_dir)
        FileUtils.remove_dir(repo_dir)
      end
      
      # Clone the repository.
      puts "Cloning #{self.data['repository']} to #{repo_dir}"
      Git.clone(self.data['repository'], project_name, :path => clone_dir)
      repo_dir
    end
    
    # Gets the path to the README file for the project.
    #
    #  +repo_dir+ is the path to the directory containing the checkout-out repository.
    #
    # Returns String path to the readme file.
    def get_readme_path(repo_dir)
      Find.find(repo_dir) do |file|
        if File.basename(file) =~ /^README(\.[a-z0-9\.]+)?$/i
          return file
        end
      end
      
      throw "No README file found in #{repo_dir}"
    end
    
    # Creates a zipped archive file of the downloaded repository.
    #
    #  +repo_dir+     is the path to the directory containing the checkout-out repository.
    #  +project_name+ is the name of the project to process.
    #  +project_dir+  is the relative path from the base directory to the project folder.
    #  +version+      is the version number to use when creating the zip file.
    #
    # Returns String path to the zip file.
    def create_zip(repo_dir, project_name, project_dir, version)
      # Create the target folder if it doesn't exist.
      target_folder = File.join(@site.config['destination'], project_dir)
      unless File.directory?(target_folder)
        FileUtils.mkdir_p(target_folder)
      end
      
      # Decide the name of the bundle - use a timestamp if no version is available.
      unless version
        version = Time.now.strftime('%Y%m%d%H%M') 
      end
      zip_filename    = "#{project_name}.#{version}.zip"
      bundle_filename = File.join(target_folder, zip_filename)
      puts "Creating #{bundle_filename}"
      
      # Remove the bundle if it already exists.
      if File.file?(bundle_filename)
        File.delete(bundle_filename)
      end

      Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) do |zipfile|
        Find.find(repo_dir) do |path|
          # Remove .git files.
          Find.prune if File.basename(path) == '.git'
          # Trim the temp dir stuff off, leaving just the repo folder.
          parent = File.expand_path(File.dirname(repo_dir)) + '/'
          dest = path.sub parent, ''
          # Add the file to the bundle.
          zipfile.add(dest, path) if dest
        end 
        
        # Add a static file entry for the zip file, otherwise Site::cleanup will remove it.
        @site.static_files << Jekyll::StaticProjectFile.new(@site, @site.dest, @dir, zip_filename)
      end
      
      # Set permissions.
      File.chmod(0644, bundle_filename)
      
      File.basename(bundle_filename)
    end
    
    # Get the version of the project from version.txt if possible.
    #
    #  +repo_dir+ is the path to the directory containing the checkout-out repository.
    #
    # Returns String version number of the project if it exists, false otherwise.
    def get_version(repo_dir)
      Find.find(repo_dir) do |file|
        if File.basename(file) =~ /^VERSION(\.[a-z0-9]+)?/i
          # Remove *all* whitespace from the version, since we may be using it in a filename.
          return File.read(file).gsub(/\s+/, '')
        end
      end
      
      false
    end
    
  end
  
  
  # The Site class is a built-in Jekyll class with access to global site config information.
  class Site
    
    # Folder containing project .yml files.
    PROJECT_FOLDER = '_projects'
    
    # Loops through the list of project pages and processes each one.
    def write_project_indexes
      base_dir = self.config['project_dir'] || 'projects'
      projects = self.get_project_files
      projects.each do |project_config_path|
        project_name = project_config_path.sub(/^#{PROJECT_FOLDER}\/([^\.]+)\..*/, '\1')
        self.write_project_index(File.join(base_dir, project_name), project_config_path, project_name)
      end
    end
    
    # Writes each project page.
    #
    #  +project_dir+         is the relative path from the base directory to the project folder.
    #  +project_config_path+ is the String path to the project's yaml config file.
    #  +project_name+        is the name of the project to process.
    def write_project_index(project_dir, project_config_path, project_name)
      index = ProjectIndex.new(self, self.source, project_dir, project_config_path, project_name)
      # Check that the project has been published.
      if index.data['published']
        index.render(self.layouts, site_payload)
        index.write(self.dest)
        # Record the fact that this page has been added, otherwise Site::cleanup will remove it.
        self.static_files << Jekyll::StaticProjectFile.new(self, self.dest, project_dir, 'index.html')
      end
    end
    
    # Gets a list of files in the _projects folder with a .yml extension.
    #
    # Return Array list of project config files.
    def get_project_files
      projects = []
      Find.find(PROJECT_FOLDER) do |file|
        if file=~/.yml$/
          projects << file
        end
      end
      
      projects
    end
    
  end
  

  # Sub-class Jekyll::StaticFile to allow recovery from an unimportant exception when writing zip files.
  class StaticProjectFile < StaticFile
    def write(dest)
      super(dest) rescue ArgumentError
      true
    end
  end
  
  
  # Jekyll hook - the generate method is called by jekyll, and generates all the project pages.
  class GenerateProjects < Generator
    safe true
    priority :low

    def generate(site)
      site.write_project_indexes
    end

  end
  
end