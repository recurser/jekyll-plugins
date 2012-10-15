
About
-----

This is a collection of [Jekyll](https://github.com/mojombo/jekyll) plugins and generators that I've written for use on [recursive-design.com](http://recursive-design.com/).

License
-------

The plugins are distributed under the [MIT License](http://en.wikipedia.org/wiki/MIT_license). See the [License](https://github.com/recurser/jekyll-plugins/blob/master/LICENSE) file for details.

Installation
------------

To install the plugins simply put them in a directory named _\_plugins_ in your project directory.

Bug Reports
-----------

If you come across any problems, please [create a ticket](https://github.com/recurser/jekyll-plugins/issues) and we'll try to get it fixed as soon as possible.

Want to make your own plugins?
------------------------------

More information on the Jekyll plugin architecture is available from the [Jekyll wiki](https://github.com/mojombo/jekyll/wiki/Plugins).


generate_projects.rb
====================

A generator that creates project pages for Jekyll sites from git repositories.

This was inspired by the project pages on GitHub, which use the project _README_ file as the index page. It takes git repositories, and automatically builds project pages for them using the _README_ file, along with downloadable zipped copies of the projects themselves (for example, the project page for this [plugin repository](http://recursive-design.com/projects/jekyll-plugins/) is auto-generated with this plugin).

Usage
-----

To use it, simply drop the _generate_projects.rb_ script into the _\_plugins_ directory of your Jekyll site. Next, create a _\_projects_ folder in the base of your Jekyll site. This folder should contain _.yml_ files describing how to build a page for your project. Here is an example _\_projects/jekyll-plugins.yml_):

``` yaml
layout:     default
title:      Jekyll Plugins
repository: git://recursive-design.com/jekyll-plugins.git
published:  true
```

How it works
------------

When you compile your Jekyll site, the plugin will download the git repository of each project in your _\_projects_ folder, create an index page from the _README_ file (using the specified layout), and create a downloadable _.zip_ file of the project. The goal is to automate the construction of online project pages, keep them in sync with _README_ documentation, and provide an up-to-date zip archive for download.

Required files
--------------

Your project's git repository should contain:

* _README_ : The contents of this will be used as the body of your project page will be created from. Any extension other than .markdown, .textile or .html will be treated as a .textile file.
* _versions.txt_ : Contains the version string (eg 1.0.0). Used when naming the downloadable zip-file (optional). If the _version.txt_ file is not available, a _YYYYMMDDHHMM_ timestamp will be used for the version instead.

Required gems
-------------

* git (>= 1.2.5)
* rubyzip (>= 0.9.4)

Available \_config.yml settings
------------------------------

* _project_dir_ : The subfolder to compile projects to (default is 'projects').

Available YAML settings
-----------------------

* _repository_ : Git repository of your project (required).
* _layout_ :     Layout to use when creating the project page.
* _title_ :      Project title, which can be accessed in the layout.
* _published_ :  Project won't be published if this is false.

There is also an optional _zip_folder_name_ setting, in case you want the unzipped folder to be named
something other than the project name. This is useful (for eaxmple) if you want it to unzip as an
OS X 'Something.app' application bundle.


generate_categories.rb
======================

A generator that creates category pages for Jekyll sites (for example our [plugin category](http://recursive-design.com/blog/category/plugin/)).

Usage
-----

To use it, simply drop the _generate_categories.rb_ script into the _\_plugins_ directory of your Jekyll site.

You should also copy the [category_index.html](https://github.com/recurser/jekyll-plugins/blob/master/_layouts/category_index.html) file to the _\_layouts_ directory of your own project. This file is provided as an example layout, and obviously you can change the HTML as you see fit.

You can also (optionally) generate an _atom.xml_ feed for each category. To do this, copy the [category_feed.xml](https://github.com/recurser/jekyll-plugins/blob/master/_includes/custom/category_feed.xml) file to the _\_includes/custom_ directory of your own project. You'll also need to copy the [octopress_filters.rb](https://github.com/recurser/jekyll-plugins/blob/master/_plugins/octopress_filters.rb) file into the _\_plugins_ directory of your project, as the _category_feed.xml_ requires a couple of extra filters.

How it works
------------

When you compile your Jekyll site, this plugin will loop through the list of categories in your site, and use the layout above to generate a page for each one with a list of links to the individual posts.

Included filters
----------------

* _category_links_ : Outputs the list of categories as comma-separated links.
* _date_to_html_string_ : Outputs the post.date as formatted html, with hooks for CSS styling.

Available \_config.yml settings
------------------------------

* _category_dir_ : The subfolder to build category pages in (default is 'categories').
* _category_title_prefix_ : The string used before the category name in the page title (default is 'Category: ').


generate_sitemap.rb
===================

A simple generator that creates a _sitemap.xml_ page for Jekyll sites, suitable for submission to Google etc (for example the _sitemap.xml_ for [recursive-design.com](http://recursive-design.com/sitemap.xml).

Usage
-----

To use it, simply drop the _generate_sitemap.rb_ script into the _\_plugins_ directory of your Jekyll site.

How it works
------------

When you compile your Jekyll site, the plugin will loop through the list of pages in your site, and generate an entry in _sitemap.xml_ for each one.

Available YAML settings
-----------------------

* _changefreq_ : How often this page will change. This setting is optional, but if specified its value must be one of `always`, `hourly`, `daily`, `weekly`, `monthly`, `yearly`, or `never`. See [the sitemap specification](http://www.sitemaps.org/protocol.php#xmlTagDefinitions) for more details on what this is used for. By default, this property is omitted for static pages and `never` for the files in `_posts` (since these are typically blog entries or the like).


Change history
==============

* **Version 0.2.1 (2012-10-15)** : Merged some updates from [Octopress](https://github.com/imathis/octopress/blob/master/plugins/category_generator.rb) back in.
  * Add support for _atom.xml_ feed generation for categories.
  * Improved handling of multibyte and multi-word category names in URLs.
* **Version 0.2.0 (2012-10-14)** :
  * Add support for priority in _generate_sitemap.rb_ (thanks [hez](https://github.com/hez)!).
  * Remove hard-coded category directory in _generate_categories.rb_ (thanks [ghinda](https://github.com/ghinda) and [MrWerewolf](https://github.com/MrWerewolf)!).
  * Improved slash handling in _generate_sitemap.rb_.
* **Version 0.1.8 (2011-08-15)** : A bunch of fixes and improvements (thanks [bdesham](https://github.com/bdesham)!).
* **Version 0.1.7 (2011-07-19)** : Sitemap base URL fix (thanks [ojilles](https://github.com/ojilles)!).
* **Version 0.1.6 (2011-05-21)** : Added optional _zip_folder_name_ YAML config setting.
* **Version 0.1.5 (2011-05-21)** : Replace github-style code markup to pygments-compatible 'highlight' format.
* **Version 0.1.4 (2011-05-08)** : Applied patch to fix permalink problem in _generate_sitemap.rb_ (thanks [ejel](https://github.com/ejel)!).
* **Version 0.1.3 (2011-01-06)** : Fixed pygments code formatting bug introduced in _generate_projects.rb_ v0.1.2.
* **Version 0.1.2 (2011-01-06)** : Add generated pages to the Site::pages list, to stop them being deleted automatically by Site::cleanup(); Fixed a file extension problem with _generate_projects.rb_.
* **Version 0.1.1 (2010-12-10)** : Use _mtime_ instead of _ctime_ for sitemap modification dates; Fixed sitemap extension bug.
* **Version 0.1.0 (2010-12-08)** : Initial release.


Contributing
============

Once you've made your commits:

1. [Fork](http://help.github.com/fork-a-repo/) jekyll-plugins
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create a [Pull Request](http://help.github.com/pull-requests/) from your branch
5. That's it!


Author
======

Dave Perrett :: mail@recursive-design.com :: [@recurser](http://twitter.com/recurser)


Copyright
=========

Copyright (c) 2010 Dave Perrett. See [License](https://github.com/recurser/jekyll-plugins/blob/master/LICENSE) for details.

