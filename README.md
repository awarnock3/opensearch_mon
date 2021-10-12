<div id="top"></div>

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]



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

Here's a blank template to get started: To avoid retyping too much info. Do a search and replace with your text editor for the following: `awarnock3`, `opensearch-mon`, `twitter_handle`, `linkedin_username`, `email`, `email_client`, `project_title`, `project_description`

<p align="right">(<a href="#top">back to top</a>)</p>



### Built With

* [Dancer2](https://metacpan.org/pod/Dancer2)
* [JQuery](https://jquery.com)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

This is an example of how to list things you need to use the software and how to install them.
* npm
  ```sh
  npm install npm@latest -g
  ```

### Installation

1. Get a free API Key at [https://example.com](https://example.com)
2. Clone the repo
   ```sh
   git clone https://github.com/awarnock3/opensearch-mon.git
   ```
3. Install NPM packages
   ```sh
   npm install
   ```
4. Enter your API in `config.js`
   ```js
   const API_KEY = 'ENTER YOUR API';
   ```

### Create the database

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

Load the Source table first because there are foreign key constraints to it from other tables.

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
<pre>
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

</pre>

### Configure the Web Server

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage



This system is built to monitor the transition of the CWIC project from operational mode into part of the NASA CMR task. The former CWIC partner sites are tested here on a regular basis to help with early diagnosis of potential problems.

The Monitoring project consists of three components - a monitoring database, a command-line perl program (cmr_monitor.pl) which populates the database by testing various OpenSearch URLs for CWIC data partners, and a web application (Monitor) using the perl-based Dancer2 framework to present the results of the URL testing and some related statistics.

The source code for both cmr_monitor.pl and the Monitor Web App are open source and freely available upon request.
About cmr_monitor.pl

./cmr_monitor.pl [--help|--man|--verbose|--batch|--save|--source=XXX|--osdd_only|--granule_only]

Monitor CMR and remote CWIC hosts for responses. Usually run out of cron. There is a single entry available (see --source). If neither --source nor --batch are specified, presents a menu for selecting a single source.

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
            

About the Monitor Web Application
The Monitor Web App provides 5 tabs:

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


_For more examples, please refer to the [Documentation](https://example.com)_

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

Your Name - [@twitter_handle](https://twitter.com/twitter_handle) - email@email_client.com

Project Link: [https://github.com/awarnock3/opensearch-mon](https://github.com/awarnock3/opensearch_mon)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS
## Acknowledgments

* []()
* []()
* []()

<p align="right">(<a href="#top">back to top</a>)</p>

-->

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
