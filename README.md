Installation
===========

1. Download solr-4.9.x.tgz (4.9.0 or above)

    ```
    > tar xvzf solr-4.9.0.tgz
    > cd solr-4.9.0
    > cd example
    ```

2. Clone config files into the installation directory

    ```
    > git clone git@github.com:cidvbi/patric_solr.git
    ```

3. Copy Oracle JDBC library

    ```
    > copy ojdbc6.jar ./solr-webapp/webapp/WEB-INF/lib/
    ```

4. Start Solr instance

    ```
    java -Dsolr.solr.home=patric_solr -jar start.jar
    ```

In order to perform a data import, one must configure a JNDI DataSource named jdbc/DIHDataSource. Note that the DIH
handlers require a standalone jetty in order to get JNDI support

For Jetty 9.x, this involves the following steps:

1. Adding a JNDI Datasource.  For example, in ${jetty.base}/etc/jetty.xml:

    ```xml
    
	<New id="DIHDataSource" class="org.eclipse.jetty.plus.jndi.Resource">
		<Arg></Arg>
		<Arg>jdbc/DIHDataSource</Arg>
		<Arg>
			<New class="oracle.jdbc.pool.OracleDataSource">
				<Set name="DriverType">thin</Set>
				<Set name="URL">jdbc:oracle:thin:@SERVER:1521:SID</Set>
				<Set name="User">USERNAME</Set>
				<Set name="Password">PASSWORD</Set>
				<Set name="connectionCachingEnabled">true</Set>
				<Set name="connectionCacheProperties">
					<New class="java.util.Properties">
						<Call name="setProperty">
							<Arg>MinLimit</Arg>
							<Arg>5</Arg>
						</Call>
					</New>
				</Set>
			</New>
		</Arg>
	</New>
   
     ```

2. Copy ojdbc.jar to {$jetty.base}/lib/ext

3. Copy solr.war to {$jetty.base}/webapps/

4. Expand solr.war (mkdir -p webapps/solr && cd webapps/solr && jar -xvf ../solr.war)

5. Edit webapps/solr/WEB-INF/web.xml and add the following:

   ``` 
        <resource-ref>
           <res-ref-name>jdbc/DIHDataSource</res-ref-name>
           <res-type>javax.sql.DataSource</res-type>
           <res-auth>Container</res-auth>
        </resource-ref>
   ``` 

6. Add --module=plus to ${jetty.base}/start.ini



