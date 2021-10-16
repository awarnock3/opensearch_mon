<div id="top"></div>

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]
-->



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/awarnock3/opensearch_mon">
    OpenSearch-mon
<!--    <img src="images/logo.png" alt="Logo" width="80" height="80"> -->
  </a>

  <h3 align="center">opensearch-mon</h3>

  <p align="center">
    A tool for monitoriing OpenSearch servers
    <!--
    <br />
    <a href="https://github.com/awarnock3/opensearch-mon"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/awarnock3/opensearch-mon">View Demo</a>
    ·
    <a href="https://github.com/awarnock3/opensearch-mon/issues">Report Bug</a>
    ·
    <a href="https://github.com/awarnock3/opensearch-mon/issues">Request Feature</a>
    -->
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

<!-- [![Product Name Screen Shot][product-screenshot]](https://example.com) -->

This project was originally built to monitor the transition of the
CWIC project from operational mode into part of the NASA CMR task. The
former CWIC partner sites are tested here on a regular basis to help
with early diagnosis of potential problems. It can be used as a
general-purpose monitoring application for OpenSearch servers,
particularly those which complay with the [CEOS OpenSearch Best
Practices](https://ceos.org/ourwork/workinggroups/wgiss/access/opensearch/)
documentation.

The Monitoring project consists of three components - a monitoring
database, a command-line perl program (os_monitor.pl) which populates
the database by testing various OpenSearch URLs, and a web application
(Monitor) using the perl-based Dancer2 framework to present the
results of the URL testing and some related statistics.


<p align="right">(<a href="#top">back to top</a>)</p>



### Build With

* [Dancer2](https://metacpan.org/pod/Dancer2)
* [JQuery](https://jquery.com)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

The command-line script requires a number of Perl modules. All should
be easily available from MetaCPAN.org

-  Authen::SASL
-  Carp
-  Config::Tiny
-  DBI
-  Data::Dumper::Concise # Only used for debugging
-  Email::Sender::Transport::SMTP
-  Email::Stuffer
-  Exporter
-  FindBin
-  Getopt::Long
-  LWP
-  LWP::Protocol::https
-  LWP::UserAgent
-  MIME::Types
-  Net::SMTP 3.0
-  Pod::Usage
-  Term::ReadKey
-  WWW::Mechanize::Timed
-  XML::LibXML
-  XML::LibXML::PrettyPrint

### Installation

Once you have cloned the repository into your desired location (I use
`/usr/local/src`) and installed the necessary modules, the command-line
script `os_monitor.pl` is ready to use. I run it out of cron every 12
hours as a sanity check.

The repository also contains the Dancer2 modules to run the web
interface. It is in `./web/Monitor`. This is the place I suggest
installing Dancer2. That will keep all of the code from this
repository in one place, making updates easy.

### Create the database

The first step is to create the database. There are 4 tables to
create, 3 of which require populating with data of your choice. The
file `./sql/os_monitor.sql` will create the tables. The other 3
individual *.sql files will populate the database with sample data.

- Table *init*

    Contains basic configuration data, including the path to the `os_monitor.pl` script

- Table *source*

    Contains the OpenSearch sources to be monitored

- Table *links*

    Contains the base, OSDD and granule request URLs for the sources in *source*

- Table *monitor*

    Populated by running `os_monitor.pl` on the sources in the *source* table


        $ mysql --user <username> -p
        Enter password: 
        Welcome to the MariaDB monitor.  Commands end with ; or \g.
        Your MariaDB connection id is 224
        Server version: 10.3.28-MariaDB MariaDB Server

        Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

        Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

        MariaDB [(none)]> create database <dbname>;
        Query OK, 1 row affected (0.103 sec)
        MariaDB [(none)]> quit
        Bye

        $ mysql --user <dbuser> -p <dbname> < sql/os_monitor.sql 
        Enter password: 
        $

### Populate the database tables

Load the *source* table first because there are foreign key constraints to it from other tables.


        $ mysql --user <dbuser> -p <dbname> < sql/source.sql 
        Enter password: 
        $ mysql --user <dbuser> -p <dbname> < sql/links.sql 
        Enter password: 
        $ mysql --user <dbuser> -p <dbname> < sql/config.sql 
        Enter password: 
        $

### Configure the ini file

For the os_monitor script:


        $ vi os_monitor.ini
        [database]
        dbname = <dbname>
        dbuser = <dbuser>
        dbpass = <dbpassword>

        [mail]
        server = <smtphost>
        sender = <senderemail>
        login = <smtpuser>
        password = <smtppass>
        recipients = <emails>


### Install Dancer2

Follow the directions in the Dancer2 documentation to install Dancer2
into web/Monitor. Don't forget that you will have to configure the
database connection in config.yml for the database plugin. For MySQL
or MariaDB, it will look like this:


    Database:
        driver: 'mysql'
        database: <dbname>
        host: 'localhost'
        port: 3306
        username: <dbuser>
        password: <dbpass>
        connection_check_threshold: 10
        dbi_params:
            RaiseError: 1
            AutoCommit: 1
        on_connect_do: ["SET NAMES 'utf8'", "SET CHARACTER SET 'utf8'" ]
        log_queries: 1


### Configure the Web Server

I configure Apache to point to the osmon web app by defining a ScriptAlias in httpd.conf:


    ScriptAlias /osmon/ /usr/local/src/os_monitor/web/Monitor/public/dispatch.cgi/
    <Directory "/usr/local/src/os_monitor/web/Monitor/public">
       AllowOverride None
       Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
       Require all granted
       AddHandler cgi-script .cgi
    </Directory>


<p align="right">(<a href="#top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage

### os_monitor.pl


    ./os_monitor.pl [--help|--man|--verbose|--batch|--save|--source=XXX|--osdd_only|--granule_only]

Monitor remote OpenSearch hosts for responses. Usually run out of
cron. There is a single entry available (see `--source`). If neither
`--source` nor `--batch` are specified, the program presents a menu
for selecting a single source.

            --help
            Show this help

            --man
            Show the man page

            --verbose
            Print extra output, notably retrieved XML

            --batch
            Run in batch mode - test each active provider in cmr.ini

            --save
            Save results to the database

            --mail
            Send an email alert if any errors occur

            --source=XXX
            Test just one source specified in cmr.ini

            --osdd_only
            Just test the OSDD link (skip the granules)

            --granule_only
            Just test the granule request link (skip the OSDD)

### Monitor Web Application


The Monitor Web App provides 6 tabs:

    Home/Statistics
        Current summary statistics on testing results for the CWIC data partners
    Results
        The full log of the testing results table from the Monitor database
    Sources
        Contents of the monitoring table of sources
    Links
        Stored OpenSearch links for the CWIC data partners
    About
        General information about the CWIC project and the Monitoring application
    Contact Us
        Contact information for the CWIC team


<p align="right">(<a href="#top">back to top</a>)</p>

<!-- ROADMAP 
## Roadmap

- [] Feature 1
- [] Feature 2
- [] Feature 3
    - [] Nested Feature

See the [open issues](https://github.com/awarnock3/opensearch-mon/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#top">back to top</a>)</p>

-->

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

<!--
Your Name - [@twitter_handle](https://twitter.com/twitter_handle) - email@email_client.com
-->
Project Link: [https://github.com/awarnock3/opensearch-mon](https://github.com/awarnock3/opensearch_mon)

<p align="right">(<a href="#top">back to top</a>)</p>



## Acknowledgments

The [CEOS/WGISS Integrated Catalog](https://ceos.org/ourwork/workinggroups/wgiss/access/cwic/) (CWIC)
is supported by [A/WWW Enterprises](https://www.awcubed.com/)
under subcontract from [Science Systems and Applications, Inc.](https://ssaihq.com) (SSAI) on behalf of [NASA](https://www.nasa.gov).


<!-- ACKNOWLEDGMENTS

* []()
* []()
* []()


-->

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links
[contributors-shield]: https://img.shields.io/github/contributors/awarnock3/opensearch-mon.svg?style=for-the-badge
[contributors-url]: https://github.com/awarnock3/opensearch-mon/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/awarnock3/opensearch-mon.svg?style=for-the-badge
[forks-url]: https://github.com/awarnock3/opensearch-mon/network/members
[stars-shield]: https://img.shields.io/github/stars/awarnock3/opensearch-mon.svg?style=for-the-badge
[stars-url]: https://github.com/awarnock3/opensearch-mon/stargazers
[issues-shield]: https://img.shields.io/github/issues/awarnock3/opensearch-mon.svg?style=for-the-badge
[issues-url]: https://github.com/awarnock3/opensearch-mon/issues
[license-shield]: https://img.shields.io/github/license/awarnock3/opensearch-mon.svg?style=for-the-badge
[license-url]: https://github.com/awarnock3/opensearch-mon/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/linkedin_username
[product-screenshot]: images/screenshot.png
-->
