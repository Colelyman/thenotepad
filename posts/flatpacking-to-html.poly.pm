#lang pollen

◊(define-meta title "Flatpacking a Site: From CMS to Static Files")
◊(define-meta published "2016-10-21")

I just finished converting ◊link["https://howellcreekradio.com"]{a site} from running on a database-driven CMS (Textpattern in this case) to a bunch of static HTML files. No, I don’t mean I switched to a static site generator like Jekyll or Octopress, I mean it’s just plain HTML files and nothing else.

I call this “flatpacking” the site. It’s the responsible thing to do when you’re done with a website. Don’t delete it: that's just selfish. Rather, strip out all the complicated mechanisms for updating it, upload it somewhere and leave it there until you die. You never know what use someone might get out of it. Since it’s just a bunch of HTML files now, it can run for years with next to no maintenance.

◊section[#:id "how-to-flatpack"]{How to Flatpack}

Before getting rid of Textpattern and its database, I made use of it to simplify the site as much as possible. It’s going to be incredibly tedious to fix or change anything later on so now’s the time to do it.

◊ul{
◊item{I stripped out all external dependencies, such as TypeKit and any script-based analytics. In place of Typekit I used a self-hosted font for the headings and just switched to Georgia for the body text.}
◊item{I removed unneeded internal links from the page templates. For example, the privacy policy and the “different ways to subscribe” guide both were removed. I made the “episodes” page one giant list of all the episodes instead of being broken up into 20 pages.}
◊item{Finally, I edited or cut any text in the page templates to make the site’s “archival status” clear.}
}

Next, on the webserver, I made a temp directory (outside the site’s own directory) and downloaded static copies of all the site’s pages into it with the ◊code{wget} command:

◊blockcode{wget --recursive --domains howellcreekradio.com --html-extension howellcreekradio.com/}

This downloaded everything, including images and MP3 files which I didn’t need. I deleted those until I just had the ◊code{.html} files left.

◊subsection[#:id "fixing-some-links"]{Fixing some links}

I was almost done but there was a bit of updating to do that couldn’t be done from within Textpattern. The home page on this site allowed you to click “Older” and “Newer” links at the bottom in order to browse through the episodes, and I wanted to keep it this way. These older/newer links were generated by the CMS with POST-style URLS: ◊code{http://site.com/?pg=2} and so on. When used with the ◊code{--html-extension} option, ◊code{wget} downloads this as ◊code{index.html?pg=2.html}. This will never do for a filename, so these all needed to be renamed, and the links needed to be updated. I happen to use ZSH which comes with an alternative to the standard ◊code{mv} command called ◊code{zmv} that recognizes patterns:

◊blockcode{zmv 'index.html\?pg=([0-9]).html' 'page$1.html'
zmv 'index.html\?pg=([0-9][0-9]).html' 'page$1.html'}

So now these files were all named ◊code{page01.html} through ◊code{page20.html} but they still contained links in the old ◊code{?pg=} format. I was able to update these in one fell swoop with a one-liner:

◊blockcode{grep -rl \?pg= . | xargs sed -i -E 's/\?pg=([0-9]+)/page\1.html/g'}

To dissect this a bit:

◊ul{
◊item{◊code{grep -rl \?pg= .} lists all files containing the links I want to change. I pass this list to the next command with the pipe ◊code{|} character.}
◊item{The ◊code{xargs} command takes the list produced by ◊code{grep} and feeds them one by one to the ◊code{sed} command.}
◊item{The ◊code{sed} command has the ◊code{-i} option to edit the files in-place, and the ◊code{-E} option to enable regular expressions. For every file in its list, it uses ◊code{s/\?pg=([0-9]+)/page\1.html/g} as a regex-style search-and-replace pattern. You can learn more about ◊link["https://regex101.com/r/rXuSJB/1"]{the details of this search pattern} if you are new to regular expressions.}
}

◊subsection[#:id "back-up-the-cms-and-database"]{Back up the CMS and Database}

Before actually switching, I wanted to freeze-dry a copy of the old site, so to speak, in case I ever needed it again.

First I exported the database to a plain-text backup:

◊blockcode{mysqldump -u username -pPASSWORD db_name > dbbackup.sql}

Then I gzipped that ◊code{.sql} file and the whole site directory before proceeding.

◊subsection[#:id "shutting-down-the-cms-and-swapping-in-the-static-files"]{Shutting down the CMS and swapping in the static files}

Final steps:

◊ol{
◊item{Moved the HTML files I downloaded and modified above into the site’s public folder.}
◊item{Edited the site’s ◊code{.htaccess} file so that links like ◊code{site.com/about/} would be ◊link["http://httpd.apache.org/docs/2.0/misc/rewriteguide.html"]{rewritten} as ◊code{site.com/about.html}. This is going to be different depending on what CMS was being used, but essentially you want to be sure that any URL that anyone might have used as a link to your site continues to work.}
◊item{Deleted all CMS-related files like ◊code{index.php}, ◊code{css.php}, and the whole ◊code{textpattern/} directory from the site’s public folder}
}

Watch your site's logs for 404 errors for a couple of weeks to make sure you didn't miss anything.