# encoding: utf-8
#
# Jekyll post attribute (category and tag) page generator.
# http://recursive-design.com/projects/jekyll-plugins/
#
# Version: 0.2.4 (201210160037)
#
# Copyright (c) 2010 Dave Perrett, http://recursive-design.com/
# Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)
#
# A generator that creates post attribute (category and tag) pages for jekyll sites.
#
# To use it, simply drop this script into the _plugins directory of your Jekyll
# site. You should also create a file called 'category_index.html' and one
# called 'tag_index.html' in the _layouts directory of your jekyll site with the
# following contents (note: you should remove the leading '# ' characters):
#
# ================================== COPY BELOW THIS LINE ==================================
# ---
# layout: default
# ---
#
# <h1 class="category">{{ page.title }}</h1>
# <ul class="posts">
# {% for post in site.categories[page.category] %}
#     <div>{{ post.date | date_to_html_string }}</div>
#     <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
#     <div class="categories">Filed under {{ post.categories | attribute_links: "category" }}</div>
# {% endfor %}
# </ul>
# ================================== COPY ABOVE THIS LINE ==================================
#
# Make a layout file called 'tag_index.html' substituting the word 'tag' for
# 'category' in the content above.
#
# You can alter the _layout_ setting if you wish to use an alternate layout, and obviously you
# can change the HTML above as you see fit.
#
# When you compile your jekyll site, this plugin will loop through the list of
# categories and tags in your site, and use the layout above to generate a page
# for each one with a list of links to the individual posts.
#
# You can also (optionally) generate an atom.xml feed for each category and tag. To do this, copy
# the category_feed.xml file to the _includes/custom directory of your own project
# (https://github.com/recurser/jekyll-plugins/blob/master/_includes/custom/category_feed.xml).
# You'll also need to copy the octopress_filters.rb file into the _plugins directory of your
# project as the category_feed.xml requires a couple of extra filters
# (https://github.com/recurser/jekyll-plugins/blob/master/_plugins/octopress_filters.rb).
#
# Repeat for a tag_feed.xml file as well.
#
# Included filters :
# - attribute_links:     Outputs the list of categories or tags as comma-separated <a> links.
# - date_to_html_string: Outputs the post.date as formatted html, with hooks for CSS styling.
#
# Available _config.yml settings :
# - category_dir:          The subfolder to build category pages in (default is 'categories').
# - category_title_prefix: The string used before the category name in the page title (default is
#                          'Category: ').
# - tag_dir:               The subfolder to build tag pages in (default is 'tags').
# - tag_title_prefix:      The string used before the tag name in the page title (default is
#                          'Tag: ').
module Jekyll

  # The AttributePage class creates a single attribute page for the specified attribute.
  class AttributePage < Page

    # Initializes a new AttributePage.
    #
    #  +template_path+ is the path to the layout template to use.
    #  +site+          is the Jekyll Site instance.
    #  +base+          is the String path to the <source>.
    #  +attribute_dir+ is the String path between <source> and the attribute folder.
    #  +attr_type+     is the symbol specifying the attribute type (:category or :tag)
    #  +attribute+     is the attribute currently being processed.
    def initialize(template_path, name, site, base, attribute_dir, attr_type, attribute)
      @site  = site
      @base  = base
      @dir   = attribute_dir
      @name  = name

      self.process(name)

      if File.exist?(template_path)
        @perform_render = true
        template_dir    = File.dirname(template_path)
        template        = File.basename(template_path)
        # Read the YAML data from the layout page.
        self.read_yaml(template_dir, template)
        self.data[attr_type.to_s] = attribute
        # Set the title for this page.
        title_prefix              = site.config["#{attr_type}_title_prefix"] || "#{attr_type.capitalize}: "
        self.data['title']        = "#{title_prefix}#{attribute}"
        # Set the meta-description for this page.
        meta_description_prefix   = site.config["#{attr_type}_meta_description_prefix"] || "#{attr_type.capitalize}: "
        self.data['description']  = "#{meta_description_prefix}#{attribute}"
      else
        @perform_render = false
      end
    end

    def render?
      @perform_render
    end

  end

  # The AttributeIndex class creates a single attribute page for the specified attribute.
  class AttributeIndex < AttributePage

    # Initializes a new AttributeIndex.
    #
    #  +site+          is the Jekyll Site instance.
    #  +base+          is the String path to the <source>.
    #  +attribute_dir+ is the String path between <source> and the attribute folder.
    #  +attr_type+     is the symbol specifying the attribute type (:category or :tag)
    #  +attribute+     is the attribute currently being processed.
    def initialize(site, base, attribute_dir, attr_type, attribute)
      layout = "#{attr_type}_index.html"
      template_path = File.join(base, '_layouts', layout)
      super(template_path, 'index.html', site, base, attribute_dir, attr_type, attribute)
    end

  end

  # The AttributeFeed class creates an Atom feed for the specified attribute.
  class AttributeFeed < AttributePage

    # Initializes a new AttributeFeed.
    #
    #  +site+          is the Jekyll Site instance.
    #  +base+          is the String path to the <source>.
    #  +attribute_dir+ is the String path between <source> and the attribute folder.
    #  +attr_type+     is the symbol specifying the attribute type (:category or :tag)
    #  +attribute+     is the attribute currently being processed.
    def initialize(site, base, attribute_dir, attr_type, attribute)
      layout = "#{attr_type}_feed.xml"
      template_path = File.join(base, '_includes', 'custom', layout)
      super(template_path, 'atom.xml', site, base, attribute_dir, attr_type, attribute)

      # Set the correct feed URL.
      self.data['feed_url'] = "#{attribute_dir}/#{name}" if render?
    end

  end

  # The Site class is a built-in Jekyll class with access to global site config information.
  class Site

    # Creates an instance of AttributeIndex for each attribute page, renders it, and
    # writes the output to a file.
    #
    #  +attr_type+ is the symbol specifying the attribute type (:category or :tag)
    #  +attribute+ is the attribute currently being processed.
    def write_attribute_index(attr_type, attribute)
      dir_config_key = "#{attr_type}_dir"
      target_dir = GenerateAttributes.attribute_dir(self.config[dir_config_key], attr_type, attribute)
      index      = AttributeIndex.new(self, self.source, target_dir, attr_type, attribute)
      if index.render?
        # Record the fact that this pages has been added, otherwise Site::cleanup will remove it.
        self.pages << index
      end

      # Create an Atom-feed for each index.
      feed = AttributeFeed.new(self, self.source, target_dir, attr_type, attribute)
      if feed.render?
        # Record the fact that this pages has been added, otherwise Site::cleanup will remove it.
        self.pages << feed
      end
    end

    # Loops through the list of attribute pages and processes each one.
    def write_attribute_indexes(attr_type, attributes)
      layout = "#{attr_type}_index"

      if self.layouts.key? layout
        attributes.each do |attribute|
          self.write_attribute_index(attr_type, attribute)
        end

      # Throw an exception if the layout couldn't be found.
      else
        throw "No '#{layout}' layout found."
      end
    end

  end


  # Jekyll hook - the generate method is called by jekyll, and generates all of the attribute pages.
  class GenerateAttributes < Generator
    safe true
    priority :low

    DEFAULT_DIRS = {
        :category => 'categories',
        :tag      => 'tags'
    }

    def generate(site)
      site.write_attribute_indexes(:category, site.categories.keys)
      site.write_attribute_indexes(:tag, site.tags.keys)
    end

    # Processes the given dir and removes leading and trailing slashes. Falls
    # back on the default if no dir is provided.
    def self.attribute_dir(base_dir, attr_type, attribute)
      base_dir = (base_dir || DEFAULT_DIRS[attr_type]).gsub(/^\/*(.*)\/*$/, '\1')
      attribute = attribute.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase
      File.join(base_dir, attribute)
    end

  end


  # Adds some extra filters used during the attribute creation process.
  module Filters

    # Outputs a list of attributes as comma-separated <a> links. This is used
    # to output the attribute list for each post on a attribute page.
    #
    #  +attributes+ is the list of attributes to format.
    #
    # Returns string
    def attribute_links(attributes, attr_type)
      base_dir = @context.registers[:site].config["#{attr_type}_dir"]
      attributes = attributes.sort!.map do |attribute|
        attr_dir = GenerateAttributes.attribute_dir(base_dir, attr_type.to_sym, attribute)
        # Make sure the attribute directory begins with a slash.
        attr_dir = "/#{attr_dir}" unless attr_dir =~ /^\//
        "<a class='#{attr_type}' href='#{attr_dir}/'>#{attribute}</a>"
      end

      case attributes.length
      when 0
        ""
      when 1
        attributes[0].to_s
      else
        attributes.join(', ')
      end
    end

    # Outputs the post.date as formatted html, with hooks for CSS styling.
    #
    #  +date+ is the date object to format as HTML.
    #
    # Returns string
    def date_to_html_string(date)
      result = '<span class="month">' + date.strftime('%b').upcase + '</span> '
      result += date.strftime('<span class="day">%d</span> ')
      result += date.strftime('<span class="year">%Y</span> ')
      result
    end

  end

end
