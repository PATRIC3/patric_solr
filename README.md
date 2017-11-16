Installation
===========

1. Download PATRIC customized solr package from the p3_solr [releases page](https://github.com/PATRIC3/p3_solr/releases) (e.g solr-5.3.0-PATRIC.tgz).

    ```
    > tar xvzf solr-5.3.0-PATRIC.tgz
    > cd solr-5.3.0-PATRIC
    ```

2. Clone config files into the installation directory

    ```
    > git clone git@github.com:PATRIC3/patric_solr.git
    ```

3. Start Solr instance

    ```
    ./bin/solr restart -Dsolr.solr.home=./patric_solr/ -Dlucene.version=5.3
    ```
	* change lucene.version according to your lucene version
