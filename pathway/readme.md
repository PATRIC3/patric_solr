# A. Queries for Pathways Page
## 1. Filters
### 1.1 List of Pathway Class
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        distinct(ps.pathway_class) pclass 
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.algorithm = ?

// genome level
    SELECT
        distinct(ps.pathway_class) pclass 
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND genome_info_id = ? ) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.algorithm = ?
~~~
Equivalent Solr Queries:
~~~http
// taxon level
/solr/pathway/select/?q=annotation_sfg:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.mincount=1&facet.limit=-1&facet.field=pathway_class_sfg

// genome level
/solr/pathway/select/?q=annotation_sfg:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}gid:38287 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.mincount=1&facet.limit=-1&facet.field=pathway_class_sfg
~~~

### 1.2 List of Pathway Name
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        distinct ps.pathway_id pid,
        ps.pathway_name pname 
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.algorithm = ?

// genome level
...
~~~
Equivalent Solr Queries:
~~~http
// taxon level
/solr/pathway/select/?q=annotation_sfg:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.mincount=1&facet.limit=-1&facet.field=pathway_name_sfg

// genome level
...
~~~
### 1.3 List of EC Number

Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        distinct(ps.ec_number) ecnum 
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.algorithm = ?

// genome level
...
~~~
Equivalent Solr Queries:
~~~http
// taxon level
/solr/pathway/select/?q=annotation_sfg:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.mincount=1&facet.limit=-1&facet.field=ec_number

// genome level
...
~~~
### 1.4 List of Algorithms (Annotations)
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        distinct(ps.algorithm) alg 
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id 

// genome level
...
~~~
Equivalent Solr Queries:
~~~http
// taxon level
/solr/pathway/select/?q=*:*&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.mincount=1&facet.limit=-1&facet.field=annotation_sfg

// genome level
...
~~~

## 2. Pathways tab
### 2.1 Pathway List count
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        count(distinct(ps.pathway_id || ps.algorithm)) cnt  
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.algorithm = ?

// genome level
...
~~~
***This is not needed since Solr returns total hit count***

### 2.2 Pathway List
Original Oracle SQLs:
~~~sql
// taxon level
    select
        * 
    from
        ( select
            distinct ps.pathway_id,
            ps.pathway_name,
            ps.pathway_class,
            ps.algorithm,
            count(distinct(ps.genome_info_id)) genome_count,
            count(distinct(ps.na_feature_id)) gene_count,
            count(distinct(ps.ec_number)) ec_count,
            trunc((count(distinct(ps.genome_info_id || ps.ec_number))*100/(1))/count(distinct(ps.ec_number)),
            2) ec_cons,
            trunc((count(distinct ps.na_feature_id) / (count(distinct(ps.ec_number)) * count(distinct(ps.genome_info_id)))),
            2) gene_cons  
        FROM
            app.pathwaysummary ps,
            (SELECT
                genome_info_id 
            from
                app.genomesummary 
            WHERE
                complete in (
                    'Complete', 'WGS'
                )  
	             AND ncbi_tax_id in (
	                select
	                    ncbi_tax_id 
	                from
	                    sres.taxon connect 
	                by
	                    prior taxon_id = parent_id start with ncbi_tax_id = ?
	            )
			  ) gs 
        WHERE
            ps.genome_info_id = gs.genome_info_id  
            AND ps.algorithm = ? 
        GROUP BY
            pathway_id,
            pathway_name,
            pathway_class,
            algorithm 
        ORDER BY
            pathway_id ASC ) 
        where
            rownum <= ?

// genome level
...
~~~
Equivalent Solr Queries:
~~~http
// taxon level
/solr/pathway/select?q=annotation:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.mintcount=1&facet.limit=-1&facet.field=pathway_name_sfg&facet.stat=genome_count:unique(gid)&facet.stat=gene_count:unique(na_feature_id)&facet.stat=ec_count:unique(ec_number)&facet.stat=genome_ec:unique(genome_ec)

// you may have to use pathway_id instead as a key
/solr/pathway/select?q=annotation:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.mintcount=1&facet.limit=-1&facet.field=pathway_id&facet.stat=genome_count:unique(gid)&facet.stat=gene_count:unique(na_feature_id)&facet.stat=ec_count:unique(ec_number)&facet.stat=genome_ec:unique(genome_ec)

// from heliosearch 0.08, JSON facet API is introduced
/solr/pathway/select?q=*:*&fq=annotation:PATRIC&fq={!join+from=genome_id+to=genome_id+fromIndex=genome}taxon_lineage_ids:1763&rows=0
&facet=true&json.facet={stat:{field:{field:pathway_id,limit:-1,facet:{genome_count:"unique(genome_id)",gene_count:"unique(feature_id)",ec_count:"unique(ec_number)",genome_ec:"unique(genome_ec)"}}}}

// see http://heliosearch.org/json-facet-api/ for more detail

// genome level
...
~~~
### 2.3 Unique Pathway(s) Count
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        count(distinct(ps.pathway_id)) cnt 
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
             AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.algorithm = ?

// genome level
...
~~~
***This is not needed since Solr returns total hit count***

## 3. EC Numbers tab
### 3.1 EC count
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        count(distinct(ps.pathway_id || ps.algorithm || ps.ec_number)) cnt  
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id

// genome level
...
~~~
***This is not needed since Solr returns total hit count***

### 3.2 EC list
Original Oracle SQLs:
~~~sql
// taxon level
    select
        * 
    from
        ( select
            distinct ps.pathway_id,
            ps.pathway_name,
            ps.pathway_class,
            ps.algorithm,
            ps.ec_number,
            ps.ec_name,
            count(distinct(ps.genome_info_id)) genome_count,
            count(distinct(ps.na_feature_id)) gene_count  
        FROM
            app.pathwaysummary ps,
            (SELECT
                genome_info_id 
            from
                app.genomesummary 
            WHERE
                complete in (
                    'Complete', 'WGS'
                )  
	             AND ncbi_tax_id in (
	                select
	                    ncbi_tax_id 
	                from
	                    sres.taxon connect 
	                by
	                    prior taxon_id = parent_id start with ncbi_tax_id = ?
	            )
			  ) gs 
        WHERE
            ps.genome_info_id = gs.genome_info_id  
        GROUP BY
            pathway_id,
            pathway_name,
            pathway_class,
            algorithm,
            ec_number,
            ec_name 
        ORDER BY
            pathway_id,
            ec_number ASC ) 
        where
            rownum <= ?

// genome level
...
~~~
Equivalent Solr Queries:
~~~
// taxon level
/solr/pathway/select/?q=annotation_sfg:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.mincount=1&facet.limit=-1&facet.field=pathway_ec&facet.stat=genome_count:unique(gid)&facet.stat=gene_count:unique(na_feature_id)&facet.stat=ec_count:unique(ec_number)
~~~
### 3.3 Unique EC Count
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        count(distinct(ps.ec_number)) cnt 
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		 ) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id 

// genome level
...
~~~
***This is covered by the Solr query above (ec_count part in top level)***

## 4. Genes tab
### 4.1 Genes count
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        count(distinct(ps.pathway_id || ps.ec_number || ps.algorithm || ps.na_feature_id)) cnt  
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            ) 
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id 

// genome level
...
~~~
***This is not needed since Solr returns total hit count***
### 4.2 Genes List
Original Oracle SQLs:
~~~sql
// taxon level
    select
        * 
    from
        ( select
            distinct ps.genome_info_id,
            df.genome_name,
            df.accession,
            ps.na_feature_id,
            df.source_id as locus_tag,
            df.gene,
            df.product,
            ps.pathway_id,
            ps.pathway_name,
            ps.pathway_class,
            ps.algorithm,
            ps.ec_number,
            ps.ec_name  
        FROM
            app.dnafeature df,
            app.pathwaysummary ps,
            (SELECT
                genome_info_id 
            from
                app.genomesummary 
	         WHERE
	            complete in (
	                'Complete', 'WGS'
	            )  
	            AND ncbi_tax_id in (
	                select
	                    ncbi_tax_id 
	                from
	                    sres.taxon connect 
	                by
	                    prior taxon_id = parent_id start with ncbi_tax_id = ?
	            )
			  ) gs 
        WHERE
            df.na_feature_id = ps.na_feature_id 
            AND ps.genome_info_id = gs.genome_info_id  
        ORDER BY
            genome_name,
            locus_tag ASC ) 
        where
            rownum <= ?

// genome level
...
~~~
Equivalent Solr Queries:
~~~http
// taxon level
/solr/pathway/select?q=annotation:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)

// genome level
...
~~~
### 4.3 Unique Gene count
Original Oracle SQLs:
~~~sql
// taxon level
    select
        count(distinct(ps.na_feature_id)) cnt 
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
		) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id 

// genome level
...
~~~
Equivalent Solr Queries:
~~~http
// taxon level
/solr/pathway/select?q=annotation:PATRIC&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&facet=true&facet.field=gid&facet.stat=gene_count:unique(na_feature_id)

// genome level
...
~~~

# B. Queries for Single pathway map
## 1. Taxon / Genome Level Queries
### 1.1 Getting pathway info
Original Oracle SQL:
~~~sql
    SELECT
        name,
        description,
        class 
    FROM
        sres.ecpathway 
    where
        source_id = '00010'
~~~
Equivalent Solr Query:
~~~http
/solr/dict_pathway/select?q=pathway_id:00071&fl=pathway_name,pathway_class,ec_desc
~~~
### 1.2 Getting genome annotation info
Original Oracle SQLs:
~~~sql
// taxon level
    SELECT
        genome_info_id,
        rast,
        brc,
        refseq 
    from
        app.genomesummary 
    WHERE
        complete in (
            'Complete', 'WGS'
        )  
        AND ncbi_tax_id in (
           select
               ncbi_tax_id 
           from
               sres.taxon connect 
           by
               prior taxon_id = parent_id start with ncbi_tax_id = ?
        )

// genome level
    SELECT
        genome_info_id,
        rast,
        brc,
        refseq 
    from
        app.genomesummary 
    WHERE
        complete in (
            'Complete', 'WGS'
        )  
        AND genome_info_id = 284116
~~~
Equivalent Solr Queries:
~~~http
/solr/genomesummary/select?q=taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&fl=genome_info_id,rast_cds,brc_cds,refseq_cds

/solr/genomesummary/select?q=genome_info_id:284116 AND genome_status:(complete OR wgs)&fl=genome_info_id,rast_cds,brc_cds,refseq_cds
~~~
### 1.3 Getting pathway map coordination
~~~sql
// taxon level
    SELECT
        distinct d.map_name,
        d.coordinate_x,
        d.coordinate_y,
        ps.algorithm,
        ps.ec_name,
        count(distinct(ps.genome_info_id)) genome_count  
    FROM
        sres.ecpathwayenzymeclass d,
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
	           select
	               ncbi_tax_id 
	           from
	               sres.taxon connect 
	           by
	               prior taxon_id = parent_id start with ncbi_tax_id = ?
	        )
        ) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.ec_number = d.map_name    
        AND ps.ec_pathway_id = d.ec_pathway_id  
        AND d.map_type = 'enzyme'  
        AND ps.pathway_id = ? 
    GROUP BY
        d.map_name,
        d.coordinate_x,
        d.coordinate_y,
        ps.algorithm,
        ps.ec_name

// genome level
...
~~~
Equivalent Solr Queries:
~~~http
// taxon level
  // getting genome count for ec_number, annotation
/solr/pathway/select?q=pathway_id:00010&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.field=ec_number&subfacet.ec_number.field=annotation_sfg&facet.stat=genome_count:unique(gid)&facet.stat=gene_count:unique(na_feature_id)

  // getting map_location (coordination, occurence)
/solr/dict_pathway/select?q=pathway_id:00010 AND map_type:enzyme AND ec_number:("1.2.1.3" OR "1.1.1.1")

// genome level
...
~~~
### 1.4 Genome, gene count for each ec_number
~~~sql
// taxon level
    select
        distinct ps.ec_number,
        ps.algorithm,
        ps.occurrence,
        ps.ec_name,
        count(distinct(ps.genome_info_id)) genome_count,
        count(distinct(ps.na_feature_id)) gene_count  
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
	           select
	               ncbi_tax_id 
	           from
	               sres.taxon connect 
	           by
	               prior taxon_id = parent_id start with ncbi_tax_id = 120793
	        )
        ) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.pathway_id = '00010'  
        AND ps.algorithm = 'RAST' 
    GROUP BY
        ps.ec_number,
        ps.algorithm,
        ps.occurrence,
        ps.ec_name 
    ORDER BY
        ec_number ASC
~~~
***This is covered by the Solr query above***
### 1.5 Unique EC Count
~~~sql
// taxon level
    SELECT
        count(distinct ps.ec_number) cnt  
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
	           select
	               ncbi_tax_id 
	           from
	               sres.taxon connect 
	           by
	               prior taxon_id = parent_id start with ncbi_tax_id = 120793
	        ) 
        ) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.pathway_id = '00010'
        AND ps.algorithm = 'RAST'
~~~
Equivalent Solr Query:
~~~http
/solr/pathway/select?q=pathway_id:00010&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 AND genome_status:(complete OR wgs)&rows=0&facet=true&facet.field=annotation_sfg&facet.stat=ec_count:unique(ec_number)
~~~
### 1.6 Getting list of annotations
~~~sql
// taxon level
    SELECT
        distinct ps.pathway_id,
        ps.pathway_name,
        ps.algorithm  
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
	           select
	               ncbi_tax_id 
	           from
	               sres.taxon connect 
	           by
	               prior taxon_id = parent_id start with ncbi_tax_id = 120793
	        ) 
        ) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id 
~~~
***This can be covered with the query above***

### 1.7 Getting pathway map path objects (Do we use this?)
~~~sql
    SELECT
        d.map_name,
        d.coordinate_x,
        d.coordinate_y,
        d.map_width,
        d.map_height 
    FROM
        sres.ecpathwayenzymeclass d,
        sres.ecpathway c 
    WHERE
        d.map_type = 'path' 
        AND d.ec_pathway_id = c.ec_pathway_id   
        AND c.source_id= '00071'
~~~
***Are we using this? We don't have map_type = 'path' in DB.***
### 1.8 Getting pathway map emzyme objects
Original Oracle SQL:
~~~sql
    SELECT
        d.coordinate_x,
        d.coordinate_y,
        e.ec_number,
        e.description 
    FROM
        sres.ecpathwayenzymeclass d,
        sres.enzymeclass e,
        sres.ecpathway c 
    WHERE
        d.map_type = 'enzyme' 
        AND e.enzyme_class_id=d.enzyme_class_id  
        AND c.source_id = '00071' 
        AND c.ec_pathway_id = d.ec_pathway_id
~~~
Equivalent Solr Query:
~~~http
/solr/dict_pathway/select?q=pathway_id:00071 map_type:enzyme&fl=map_type,map_location,ec_number,ec_desc
~~~
## 2. Feature Level Pathway
### 2.1 Getting pathway list
Original Oracle SQL:
~~~sql
	select
        * 
    from
        ( SELECT
            distinct(ps.pathway_id),
            ps.na_feature_id,
            ps.pathway_name,
            ps.pathway_class,
            ps.algorithm,
            ps.ec_number,
            ps.occurrence,
            ps.ec_name,
            ps.ncbi_tax_id,
            ps.genome_info_id  
        FROM
            app.pathwaysummary ps  
        WHERE
            1=1  
            AND ps.na_feature_id = 215717469
        ORDER BY
            pathway_id ASC ) 
    where
        rownum <= ?
~~~
Equivalent Solr Query:
~~~http
// all fields except occurrence
/solr/pathway/select?q=na_feature_id:215717469&fl=pathway_id,pathway_name,pathway_class,annotation,ec_number,ec_name,taxon_id,genome_info_id,na_feature_id

// occurrence
/solr/dict_pathway/select?q=*:*&fq={!join from=pathway_id to=pathway_id fromIndex=pathway}na_feature_id:215717469&fq={!join from=ec_number to=ec_number fromIndex=pathway}na_feature_id:215717469&fl=pathway_id,ec_number,occurrence
~~~
### 2.2 Getting pathway occurrence
Original Oracle SQL:
~~~sql
    SELECT
        distinct ps.ec_number,
        ps.ec_name,
        ps.occurrence  
    FROM
        app.pathwaysummary ps  
    WHERE
        ps.na_feature_id = '215717469' 
        AND ps.pathway_id = '00910'
~~~
Equivalent Solr Query:
~~~http
/solr/dict_pathway/select?q=pathway_id:00910&fq={!join from=ec_number to=ec_number fromIndex=pathway}na_feature_id:215717469&fl=ec_number,ec_desc,occurrence
~~~
### 2.3 Getting pathway coordination
Original Oracle SQL:
~~~sql
    SELECT
        distinct d.map_name,
        d.coordinate_x,
        d.coordinate_y  
    FROM
        sres.ecpathwayenzymeclass d,
        app.pathwaysummary ps  
    WHERE
        ps.na_feature_id in (
            215717469
        )  
        AND ps.ec_number = d.map_name 
        AND d.ec_pathway_id = ps.ec_pathway_id 
        AND ps.pathway_id = '00910'
~~~
Equivalent Solr Query:
~~~http
/solr/dict_pathway/select?q=pathway_id:00910&fq={!join from=ec_number to=ec_number fromIndex=pathway}na_feature_id:(215717469)&fl=map_name,map_location
~~~

# C. Queries for Heatmap
### 1.1 gene count
Original Oracle SQL:
~~~sql
    SELECT
        distinct ps.genome_info_id,
        ps.algorithm,
        ps.ec_number,
        ps.ec_name,
        count(distinct(ps.na_feature_id)) gene_count  
    FROM
        app.pathwaysummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            ) 
        ) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.pathway_id = ?  
        AND ps.algorithm = ? 
    GROUP BY
        ps.genome_info_id,
        ps.algorithm,
        ps.ec_number,
        ps.ec_name
~~~
Equivalent Solr Query:
~~~http
/solr/pathway/select?q=annotation_sfg:PATRIC AND pathway_id:00010&fq={!join from=genome_info_id to=gid fromIndex=genomesummary}taxon_lineage_ids:120793 genome_status:(complete OR wgs)&rows=0&facet=true&facet.limit=-1&facet.field=genome_ec&facet.stat=gene_count:unique(na_feature_id)
~~~
### 1.2 genome info
Original Oracle SQL:
~~~sql
    SELECT
        distinct ps.genome_info_id,
        ps.genome_name 
    FROM
        app.genomesummary ps,
        (SELECT
            genome_info_id 
        from
            app.genomesummary 
        WHERE
            complete in (
                'Complete', 'WGS'
            )  
            AND ncbi_tax_id in (
                select
                    ncbi_tax_id 
                from
                    sres.taxon connect 
                by
                    prior taxon_id = parent_id start with ncbi_tax_id = ?
            )
        ) gs 
    WHERE
        ps.genome_info_id = gs.genome_info_id  
        AND ps.refseq = 1 
    ORDER BY
        ps.genome_name
~~~
Equivalent Solr Query:
~~~http
/solr/genomesummary/select?q=taxon_lineage_ids:120793 AND refseq_cds:[1 TO *]
~~~
# D. Queries for Enrichment tool
### 1.1 gene count
~~~sql
    select
        count(distinct(na_feature_id)) cnt 
    from
        app.pathwaysummary 
    where
        (
            na_feature_id in (
                215717469
            )
        )
~~~
***This is not needed since Solr returns total hit count***
### 1.2 Pathway Summary Count
~~~sql
    select
        count(*) cnt 
    from
        ( select
            pathway_name opname,
            pathway_id opid,
            count(distinct(na_feature_id)) ocnt  
        from
            app.pathwaysummary  
        where
            (
                na_feature_id in (
                    215717469
                )
            ) 
        group by
            pathway_name,
            pathway_id) obs,
        (select
            pathway_name epname,
            pathway_id epid,
            count(distinct(na_feature_id)) ecnt  
        from
            app.pathwaysummary  
        where
            genome_info_id in (
                select
                    distinct genome_info_id 
                from
                    app.pathwaysummary  
                where
                    (
                        na_feature_id in (
                            215717469
                        )
                    ) 
            ) 
            and algorithm = 'RAST' 
        group by
            pathway_name,
            pathway_id) exp 
        where
            obs.opid = exp.epid 
~~~
***This will be covered by the query below***
### 1.3 List of Pathway Summary
~~~sql
    select
        * 
    from
        ( select
            obs.opname pathway_name,
            obs.opid pathway_id,
            obs.ocnt ocnt,
            exp.ecnt ecnt,
            trunc(obs.ocnt*100/exp.ecnt) percentage 
        from
            ( select
                pathway_name opname,
                pathway_id opid,
                count(distinct(na_feature_id)) ocnt  
            from
                app.pathwaysummary  
            where
                (
                    na_feature_id in (
                        215717469
                    )
                ) 
            group by
                pathway_name,
                pathway_id) obs,
            (select
                pathway_name epname,
                pathway_id epid,
                count(distinct(na_feature_id)) ecnt  
            from
                app.pathwaysummary  
            where
                genome_info_id in (
                    select
                        distinct genome_info_id 
                    from
                        app.pathwaysummary  
                    where
                        (
                            na_feature_id in (
                                215717469
                            )
                        ) 
                ) 
                and algorithm = 'RAST' 
            group by
                pathway_name,
                pathway_id) exp 
            where
                obs.opid = exp.epid  
            ORDER BY
                percentage DESC ) 
        where
            rownum <= ?
~~~
Expected result:

| Pathway Name              | Pathway ID | OCNT | ECNT | Percentage |
| :------------------------ | :--------: | :--: | :--: | :--------: |
| Oxidative phosphorylation | 00190      |  1   | 41   | 2          |
| Nitrogen metabolism	     | 00910      |  1   | 51   | 1          |

~~~http
// 1. get Pathway ID, Pathwat Name & genomeID
/solr/pathway/select?q=na_feature_id:215717469&fl=pathway_name,pathway_id,gid

// 2. get pathway ID & Ocnt
/solr/pathway/select?q=na_feature_id:215717469&rows=0&facet=true&facet.limit=-1&facet.mincount=1&facet.field=pathway_id&facet.sort=gene_count&facet.stat=gene_count:unique(na_feature_id)

// 3. with genomeID, get pathway ID & Ecnt
/solr/pathway/select?q=gid:303176 AND pathway_id:(00190 OR 00910)&fq=annotation:PATRIC&rows=1&facet=true&facet.mincount=1&facet.limit=-1&facet.field=pathway_id&facet.sort=gene_count&facet.stat=gene_count:unique(na_feature_id)

// 4. Merge hash and calculate percentage on the fly
~~~