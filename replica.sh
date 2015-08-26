for d in */conf/; do
	cd $d;
	rm replication.xml; cp replication_slave.xml replication.xml;
	cd ../../
done
