# Genome Core
~~~sql
// genome counts for PATRIC annotation
    select
        nvl(sum(decode(gs.complete,'Complete',1,0)),0) complete_cnt,
        nvl(sum(decode(gs.complete,'WGS',1,0)),0) wgs_cnt,
        nvl(sum(decode(gs.complete,'Plasmid',1,0)),0) plasmid_cnt,
        count(*) all_cnt  
    from
        app.genomesummary gs,
        (select
            ncbi_tax_id 
        from
            sres.taxon connect 
        by
            prior taxon_id = parent_id start with ncbi_tax_id = ?) tx  
    where
        gs.ncbi_tax_id = tx.ncbi_tax_id  
        and gs.rast = '1' 

// genome counts for Legacy BRC annotation
...
		and gs.brc = '1'
...

// genome counts for RefSeq annotation
...
		and gs.refseq = '1'
...
~~~
Equivalent Solr Queries:
~~~http
/solr/genome/select?q=taxon_lineage_ids:1763&rows=0&facet=true
&facet.query={!key=patric}patric_cds:[1 TO *]&subfacet.patric.field=genome_status
&facet.query={!key=refseq}refseq_cds:[1 TO *]&subfacet.refseq.field=genome_status

OR query separately

/solr/genome/select?q=patric_cds:[1 TO *]+AND+taxon_lineage_ids:1763&rows=0&facet=true
&facet.field=genome_status

/solr/genome/select?q=refseq_cds:[1 TO *]+AND+taxon_lineage_ids:1763&rows=0&facet=true
&facet.field=genome_status
~~~
Results:
~~~json
{
	"responseHeader": {
		"status": 0,
		"QTime": 14,
		"params": {
			"facet": "true",
			"facet.query": ["{!key=patric}patric_cds:[1 TO *]", "{!key=refseq}refseq_cds:[1 TO *]"],
			"q": "taxon_lineage_ids:1763",
			"subfacet.patric.field": "genome_status",
			"subfacet.refseq.field": "genome_status",
			"wt": "json",
			"rows": "0"
		}
	},
	"response": {
		"numFound": 2195,
		"start": 0,
		"docs": []
	},
	"facets": {
		"patric": {
			"genome_status": {
				"stats": {
					"count": 2181
				},
				"buckets": [{
					"val": "WGS",
					"count": 2050
				}, {
					"val": "Complete",
					"count": 131
				}, {
					"val": "Plasmid",
					"count": 0
				}]
			}
		},
		"refseq": {
			"genome_status": {
				"stats": {
					"count": 1718
				},
				"buckets": [{
					"val": "WGS",
					"count": 1655
				}, {
					"val": "Complete",
					"count": 60
				}, {
					"val": "Plasmid",
					"count": 3
				}]
			}
		}
	}
}
~~~
# Feature Core
### feature count by feature type and annotation
~~~sql
    select
        name,
        sum(rast) patric,
        sum(brc) brc,
        sum(refseq) refseq 
    from
        app.featuresummary  
    where
        ncbi_tax_id in (
            select
                ncbi_tax_id 
            from
                sres.taxon connect 
            by
                prior taxon_id = parent_id start with ncbi_tax_id = ?
        )   
        and name in (
            'CDS','mRNA','ncRNA','rRNA','tRNA','tmRNA','misc_RNA'
        )  -- optional
    group by
        name 
    order by
        name
~~~
~~~http
/solr/genome_feature/select?q=*:*&fq={!join from=genome_id to=genome_id fromIndex=genome}taxon_lineage_ids:1763&rows=0&wt=&facet=true&facet.mincount=1&facet.pivot=annotation,feature_type

// optional
/solr/genome_Feature/select?q=feature_type:(cds OR *rna)&fq=...
~~~

# Taxonomy Core
~~~sql
    select
        lng.ncbi_tax_id,
        lng.name,
        cls.rank,
        cls.node_level  
    from
        (   select
            a.taxon_id,
            a.ncbi_tax_id,
            b.name,
            a.parent_id   
        from
            sres.taxon a,
            sres.taxonname b   
        where
            a.taxon_id = b.taxon_id 
            and b.name_class = 'scientific name') lng,
        cas.ncbiclassification cls   
    where
        lng.ncbi_tax_id = cls.ncbi_taxon_id  connect 
    by
        prior parent_id = taxon_id  start with ncbi_tax_id = ? 
~~~

~~~sql
// get genus
    select
        lng.ncbi_tax_id,
        lng.name,
        cls.rank,
        cls.node_level  
    from
        (   select
            a.taxon_id,
            a.ncbi_tax_id,
            b.name,
            a.parent_id   
        from
            sres.taxon a,
            sres.taxonname b   
        where
            a.taxon_id = b.taxon_id 
            and b.name_class = 'scientific name') lng,
        cas.ncbiclassification cls   
    where
        lng.ncbi_tax_id = cls.ncbi_taxon_id   
        and rank = 'genus'  connect 
    by
        prior parent_id = taxon_id  start with ncbi_tax_id = ? 
~~~

~~~sql
// get order
    select
        lng.ncbi_tax_id,
        lng.name,
        cls.rank,
        cls.node_level  
    from
        (   select
            a.taxon_id,
            a.ncbi_tax_id,
            b.name,
            a.parent_id   
        from
            sres.taxon a,
            sres.taxonname b   
        where
            a.taxon_id = b.taxon_id 
            and b.name_class = 'scientific name'  ) lng,
        cas.ncbiclassification cls  
    where
        lng.ncbi_tax_id = cls.ncbi_taxon_id   
        and cls.rank = 'order'   
        and cls.ncbi_taxon_id in (
            2037,1385,80840,213849,51291,186802,91347,186826,118969,356,766,136,72273,135623
        )  connect 
    by
        prior parent_id = taxon_id  start with ncbi_tax_id = ?
~~~

~~~sql
    select
        tx.ncbi_tax_id,
        tx.rank,
        txname.name,
        txname.unique_name_variant,
        txname.name_class  
    from
        sres.taxon tx,
        sres.taxonname txname  
    where
        tx.taxon_id = txname.taxon_id   
        and tx.ncbi_tax_id = ?   
        and txname.name_class='scientific name' 
~~~

# Trasncriptomics core
## Taxon/Genome Level
### List of experiments by given taxonID
~~~sql
select
        distinct mp.eid  
    from
        app.genexp_genomemapping mp,
        (select
            ncbi_tax_id 
        from
            sres.taxon connect 
        by
            prior taxon_id = parent_id start with ncbi_tax_id = ?) tx  
    where
        mp.ncbi_tax_id = tx.ncbi_tax_id
~~~
After adding genome_ids column to genexp-experiment core (see dataimport config for more detail),
~~~http
/solr/transcriptomics_experiment/select?q={!join from=genome_id to=genome_ids fromIndex=genome}taxon_lineage_ids:1763&fl=eid,genome_ids
~~~
## Feature Level
### List of data points
~~~sql
    select
        * 
    from
        (  select
            g.eid,
            g.accession,
            g.platform,
            g.samples,
            g.pid,
            g.locustag,
            g.avg_intensity,
            g.log_ratio,
            g.z_score,
            s.expname,
            s.channels,
            s.timepoint,
            s.organism,
            s.strain,
            s.mutant,
            s.condition,
            s.pmid,
            pm.patric_na_feature_id,
            pm.patric_locus_tag,
            pm.figfam_id  
        from
            app.genexp_gene g,
            app.genexp_sample s,
            app.genexp_genemapping pm  
        where
            g.locustag = pm.exp_locus_tag 
            and g.pid = s.pid  
            and pm.patric_na_feature_id = ? ) 
~~~
### Getting counts for strain, mutant, condition
~~~sql
// strain
    select
        rownum, A.* 
    from
        (  select
            nvl(strain, 'N/A') name,
            count(*) cnt 
        from
            (   select
                distinct pm.patric_na_feature_id,
                g.pid,
                strain  
            from
                app.genexp_gene g,
                app.genexp_sample s,
                app.genexp_genemapping pm,
                app.dnafeature nf   
            where
                g.locustag = pm.exp_locus_tag    
                and g.pid = s.pid    
                and pm.patric_na_feature_id = nf.na_feature_id    
                and pm.patric_na_feature_id = 18153995  )  
        group by
            strain 
        order by
            cnt desc ) A 

// mutant
    select
        rownum, A.* 
    from
        (  select
            nvl(mutant, 'N/A') name,
            count(*) cnt 
        from
            (   select
                distinct pm.patric_na_feature_id,
                g.pid,
                mutant  
            from
                app.genexp_gene g,
                app.genexp_sample s,
                app.genexp_genemapping pm,
                app.dnafeature nf   
            where
                g.locustag = pm.exp_locus_tag    
                and g.pid = s.pid    
                and pm.patric_na_feature_id = nf.na_feature_id    
                and pm.patric_na_feature_id = 18153995  )  
        group by
            mutant 
        order by
            cnt desc ) A 

// condition
    select
        rownum,
        A.* 
    from
        (  select
            nvl(condition,
            'N/A') name,
            count(*) cnt 
        from
            (   select
                distinct pm.patric_na_feature_id,
                g.pid,
                condition  
            from
                app.genexp_gene g,
                app.genexp_sample s,
                app.genexp_genemapping pm,
                app.dnafeature nf   
            where
                g.locustag = pm.exp_locus_tag    
                and g.pid = s.pid    
                and pm.patric_na_feature_id = nf.na_feature_id    
                and pm.patric_na_feature_id = 18153995  )  
        group by
            condition 
        order by
            cnt desc ) A 
~~~
Equivalent Solr Query:
~~~http
/solr/transcriptomics_gene/select?q=feature_id:PATRIC.83332.12.NC_000962.CDS.34.1524.fwd&rows=0&facet=true&facet.mincount=1&facet.field=strain&facet.field=mutant&facet.field=condition
~~~
### histogram for Z score and log ratio
~~~sql
// z_score
    select
        rangee,
        count(*) cnt 
    from
        (  select
            distinct pm.patric_na_feature_id,
            g.pid,
            (case    
                when z_score < -2 then 1    
                when z_score between -2.0 and -1.5 then 2    
                when z_score between -1.5 and -1 then 3    
                when z_score between -1.0 and -0.5 then 4    
                when z_score between -0.5 and 0.0 then 5    
                when z_score between 0.0 and 0.5 then 6    
                when z_score between 0.5 and 1.0 then 7    
                when z_score between 1.0 and 1.5 then 8    
                when z_score between 1.5 and 2.0 then 9    
                when z_score > 2 then 10   
            end) rangee  
        from
            app.genexp_gene g,
            app.genexp_sample s,
            app.genexp_genemapping pm  
        where
            g.locustag = pm.exp_locus_tag   
            and g.pid = s.pid  
            and pm.patric_na_feature_id = 18153995  
            and z_score is not null  ) 
    group by
        rangee  
    order by
        rangee

// log_ratio
    select
        rangee,
        count(*) cnt 
    from
        (  select
            distinct pm.patric_na_feature_id,
            g.pid,
            (case    
                when log_ratio < -2 then 1    
                when log_ratio between -2.0 and -1.5 then 2    
                when log_ratio between -1.5 and -1 then 3    
                when log_ratio between -1.0 and -0.5 then 4    
                when log_ratio between -0.5 and 0.0 then 5    
                when log_ratio between 0.0 and 0.5 then 6    
                when log_ratio between 0.5 and 1.0 then 7    
                when log_ratio between 1.0 and 1.5 then 8    
                when log_ratio between 1.5 and 2.0 then 9    
                when log_ratio > 2 then 10   
            end) rangee  
        from
            app.genexp_gene g,
            app.genexp_sample s,
            app.genexp_genemapping pm  
        where
            g.locustag = pm.exp_locus_tag   
            and g.pid = s.pid  
            and pm.patric_na_feature_id = 18153995
            and log_ratio is not null  ) 
    group by
        rangee  
    order by
        rangee
~~~
~~~http
/solr/transcriptomics_gene/select?q=feature_id:PATRIC.83332.12.NC_000962.CDS.34.1524.fwd&rows=0&facet=true&facet.range.other=before&facet.range.other=after&facet.range.start=-2&facet.range.end=2&facet.range.gap=0.5&facet.range=z_score&facet.range=log_ratio
~~~
### Correlated Genes
~~~sql
    select
        count(*) cnt   
    from
        (select
            mp1.refseq_locus_tag locustag1,
            mp2.refseq_locus_tag locustag2,
            mp2.patric_na_feature_id    
        from
            app.genexp_gene e1,
            app.genexp_genemapping mp1,
            app.genexp_gene e2,
            app.genexp_genemapping mp2   
        where
            e1.log_ratio is not null     
            and e1.pid = e2.pid 
            and e1.locustag = mp1.exp_locus_tag 
            and e2.locustag = mp2.exp_locus_tag     
            and mp1.patric_na_feature_id = ?     
            and mp1.genome_info_id = mp2.genome_info_id    
        group by
            mp1.refseq_locus_tag,
            mp2.refseq_locus_tag,
            mp2.patric_na_feature_id    
        having
            corr(e1.log_ratio, e2.log_ratio) > ?    
            and count(distinct(e1.pid)) > (
                select
                    0.8*count(distinct(gene.pid))      
                from
                    app.genexp_gene gene,
                    app.genexp_genemapping mp      
                where
                    gene.log_ratio is not null       
                    and gene.locustag = mp.exp_locus_tag       
                    and mp.patric_na_feature_id = ?
            )    
        ) co, app.dnafeature df   
    where
        co.patric_na_feature_id = df.na_feature_id 
~~~
***This is covered by the query below, since Solr provides hit counts***

~~~sql
    select
        co.locustag1,
        co.locustag2 as refseq_locus_tag,
        co.correlation,
        co.cnt,
        df.genome_info_id,
        df.genome_name,
        df.accession,
        df.source_id locus_tag,
        df.na_feature_id,
        df.start_max,
        df.end_min,
        df.na_length,
        df.is_reversed,
        df.product,
        decode(df.algorithm, 'Curation', 'Legacy BRC', 'RAST', 'PATRIC', 'RefSeq') as annotation,
        df.name as feature_type,
        df.gene,
        df.protein_id,
        df.aa_length   
    from
        (select
            mp1.refseq_locus_tag locustag1,
            mp2.refseq_locus_tag locustag2,
            mp2.patric_na_feature_id,
            round(corr(e1.log_ratio, e2.log_ratio), 3) correlation,
            count(distinct(e1.pid)) cnt    
        from
            app.genexp_gene e1,
            app.genexp_genemapping mp1,
            app.genexp_gene e2,
            app.genexp_genemapping mp2    
        where
            e1.log_ratio is not null    
            and e1.pid = e2.pid 
            and e1.locustag = mp1.exp_locus_tag 
            and e2.locustag = mp2.exp_locus_tag     
            and mp1.patric_na_feature_id = ?     
            and mp1.genome_info_id = mp2.genome_info_id    
        group by
            mp1.refseq_locus_tag,
            mp2.refseq_locus_tag,
            mp2.patric_na_feature_id    
        having
            corr(e1.log_ratio, e2.log_ratio) > ?    
            and count(distinct(e1.pid)) > (
                select
                    0.8*count(distinct(gene.pid))      
                from
                    app.genexp_gene gene,
                    app.genexp_genemapping mp      
                where
                    gene.log_ratio is not null       
                    and gene.locustag = mp.exp_locus_tag       
                    and mp.patric_na_feature_id = 18153995
            )   
        ) co, app.dnafeature df   
    where
        co.patric_na_feature_id = df.na_feature_id  
    order by
        correlation DESC
~~~
~~~http
// 0. config CorrelationQParser
// 1. get correlation values
/solr/transcriptomics_gene/select?q=genome_id:83332.12&fq={!correlation fieldId=refseq_locus_tag fieldCondition=pid fieldValue=log_ratio srcId=Rv2429 filterCutOff=0.4 filterDir=pos cost=101}
// 2. merge with other meta data

~~~
The result of 1st solr Query will be like:
~~~json
{ "correlation": {
	"numFound": 113,
	"start": 0,
	"docs": [{
		"id": "Rv0146",
		"correlation": 0.4478641463824746,
		"conditions": 461,
		"p_value": 4.004538297219427E-24
	}, {
		"id": "Rv2467",
		"correlation": 0.4200253343330222,
		"conditions": 457,
		"p_value": 5.861452282735983E-21
	}, {
		"id": "Rv2428",
		"correlation": 0.8996186598792854,
		"conditions": 462,
		"p_value": 1.2288849144120943E-167
	}, ...]
}, ...}
~~~
The performance of solr query is like below,

Organism | genome | source ID | # datapoint | Solr 1st | Solr 2nd | DB 1st | DB 2nd |
:------- | :----: | :-------: | ----------: | -------: | -------: | -----: | -----: |
S. Typhimurium str. 14028S | 101322 | STM14_5531 | 133,574 | 0.4 / 0.3 | 0.4 / 0.3 | 8.4 | 0.8 |
S. enterica str.ATCC 9150| 134188 | SPA0002 | 524,044 | 1.2 / 0.8 | 1.3 / 0.8 | 18.5 | 2.5 |
P. aeruginosa PAO1 | 58763 | PA0004 | 1,385,677 | 3.8 / 1.8 | 3.0 / 1.7 | 30.9 | 7.9 |
M. tuberculosis H37Rv | 87468 | rv2429 | 2,036,255 | 11.1 / 2.3 | 4.8 / 3.0 | 52.6 | 7.3 |
E. coli str.K-12 MG1655 | 129921 | b0002 | 4,913,434 | 13.8 / 7.7 | 11.9 / 5.2 | 90.0 | 21.9 |

total database size: 27,736,719

# ID Mpping
### PATRIC ID to uniprot (PDB)
~~~sql
// count
    select
        count(*) as cnt  
    from
        app.dnafeature nf,
        app.idmapping im,
        app.patricuniprotmapping pum  
    where
        nf.na_feature_id = pum.na_feature_id  
        and im.uniprotkb_accession = pum.uniprotkb_accession  
        and im.id_type = 'PDB' 
        and (
            nf.na_feature_id in  (
                '18148488','18148490','18148492','18148494','18148496','18148498','18148500','18148502','18148506','18148510','18148512','18148514','18148516','18148518','18148520','18148522','18148524','18148526','18148528','18148530'
            )
        ) 

// list
    select
        * 
    from
        ( select
            nf.genome_info_id,
            nf.genome_name,
            nf.accession,
            nf.na_feature_id,
            nf.na_sequence_id,
            nf.name,
            nf.source_id as locus_tag,
            decode(nf.algorithm, 'Curation', 'Legacy BRC', 'RAST', 'PATRIC', 'RefSeq') as algorithm,
            decode(nf.is_reversed, 1, '-', '+') as strand,
            nf.debug_field,
            nf.start_min,
            nf.start_max,
            nf.end_min,
            nf.end_max,
            nf.na_length,
            nf.product,
            nf.gene,
            nf.aa_length,
            nf.is_pseudo,
            nf.bound_moiety,
            nf.anticodon,
            nf.pseed_id ,
            im.id requested_data  
        from
            app.dnafeature nf,
            app.idmapping im,
            app.patricuniprotmapping pum  
        where
            nf.na_feature_id = pum.na_feature_id  
            and im.uniprotkb_accession = pum.uniprotkb_accession  
            and im.id_type = 'PDB' 
            and (
                nf.na_feature_id in  (
                    '18148488','18148490','18148492','18148494','18148496','18148498','18148500','18148502','18148506','18148510','18148512','18148514','18148516','18148518','18148520','18148522','18148524','18148526','18148528','18148530'
                )
            )  
        order by
            locus_tag ASC ) 
    where
        rownum <= ?

// unique PDB count
    select
        count(distinct id) as cnt  
    from
        app.dnafeature nf,
        app.idmapping im,
        app.patricuniprotmapping pum  
    where
        nf.na_feature_id = pum.na_feature_id  
        and im.uniprotkb_accession = pum.uniprotkb_accession  
        and im.id_type = 'PDB' 
        and (
            nf.na_feature_id in  (
                '18148488','18148490','18148492','18148494','18148496','18148498','18148500','18148502','18148506','18148510','18148512','18148514','18148516','18148518','18148520','18148522','18148524','18148526','18148528','18148530'
            )
        ) 
~~~
~~~http
// na_feature_id to PDB
/solr/id_ref/select?q=id_type:PDB&fq={!join+from=uniprot_accession+to=uniprot_accession+fromIndex=genome_feature}na_feature_id:(18148488+OR+18148490+OR+18148492+OR+18148494+OR+18148496+OR+18148498+OR+18148500+OR+18148502+OR+18148506+OR+18148510+OR+18148512+OR+18148514+OR+18148516+OR+18148518+OR+18148520+OR+18148522+OR+18148524+OR+18148526+OR+18148528+OR+18148530)

// Locus Tag to PDB
/solr/id_ref/select?q=id_type:PDB&fq={!join+from=uniprotkb_accession+to=uniprotkb_accession+fromIndex=genome_feature}alt_locus_tag:(Rv0003+OR+Rv0011c+OR+Rv0001+OR+Rv0008c+OR+Rv0007+OR+Rv0012+OR+Rv0014c+OR+Rv0016c+OR+Rv0010c+OR+Rv0015c+OR+Rv0005+OR+Rv0002+OR+Rv0009+OR+Rv0013+OR+Rv0006+OR+Rv0004)

//pseed_id to PDB

~~~

### uniprot to PATRIC
~~~sql
// count
    select
        count(*) as cnt  
    from
        app.dnafeature nf,
        app.idmapping im,
        app.patricuniprotmapping pum  
    where
        nf.na_feature_id = pum.na_feature_id  
        and im.uniprotkb_accession = pum.uniprotkb_accession  
        and im.id_type = 'PDB' 
        and (
            im.id in  (
                '3P16','3RB9','2ZJT','3IG0','3M4I','3ZKB','3ZKD','3ZM7','3IFZ','3ILW','3UC1','4G3N','1W74','1MRU','1O6Y','2FUM','2KUD','2KUE','2KUF','2KUI','3F61','3F69','3LO7','3UN7','3UPN','3UPO','3UPP'
            )
        )

// list
    select
        * 
    from
        ( select
            nf.genome_info_id,
            nf.genome_name,
            nf.accession,
            nf.na_feature_id,
            nf.na_sequence_id,
            nf.name,
            nf.source_id as locus_tag,
            decode(nf.algorithm, 'Curation', 'Legacy BRC', 'RAST', 'PATRIC', 'RefSeq') as algorithm,
            decode(nf.is_reversed, 1, '-', '+') as strand,
            nf.debug_field,
            nf.start_min,
            nf.start_max,
            nf.end_min,
            nf.end_max,
            nf.na_length,
            nf.product,
            nf.gene,
            nf.aa_length,
            nf.is_pseudo,
            nf.bound_moiety,
            nf.anticodon,
            nf.pseed_id ,
            im.id requested_data  
        from
            app.dnafeature nf,
            app.idmapping im,
            app.patricuniprotmapping pum  
        where
            nf.na_feature_id = pum.na_feature_id  
            and im.uniprotkb_accession = pum.uniprotkb_accession  
            and im.id_type = 'PDB' 
            and (
                im.id in  (
                    '3P16','3RB9','2ZJT','3IG0','3M4I','3ZKB','3ZKD','3ZM7','3IFZ','3ILW','3UC1','4G3N','1W74','1MRU','1O6Y','2FUM','2KUD','2KUE','2KUF','2KUI','3F61','3F69','3LO7','3UN7','3UPN','3UPO','3UPP'
                )
            ) 
        order by
            locus_tag ASC ) 
    where
        rownum <= ?

// unique id count
    select
        count(distinct source_id) as cnt  
    from
        app.dnafeature nf,
        app.idmapping im,
        app.patricuniprotmapping pum  
    where
        nf.na_feature_id = pum.na_feature_id  
        and im.uniprotkb_accession = pum.uniprotkb_accession  
        and im.id_type = 'PDB' 
        and (
            im.id in  (
                '3P16','3RB9','2ZJT','3IG0','3M4I','3ZKB','3ZKD','3ZM7','3IFZ','3ILW','3UC1','4G3N','1W74','1MRU','1O6Y','2FUM','2KUD','2KUE','2KUF','2KUI','3F61','3F69','3LO7','3UN7','3UPN','3UPO','3UPP'
            )
        )
~~~
~~~http
// PDB to patric
/solr/genome_feature/select?q=*:*&fq={!join+from=uniprotkb_accession+to=uniprotkb_accession+fromIndex=id_ref}id_type:PDB+AND+id_value:(3P16+OR+3RB9+OR+2ZJT+OR+3IG0+OR+3M4I+OR+3ZKB+OR+3ZKD+OR+3ZM7+OR+3IFZ+OR+3ILW+OR+3UC1+OR+4G3N+OR+1W74+OR+1MRU+OR+1O6Y+OR+2FUM+OR+2KUD+OR+2KUE+OR+2KUF+OR+2KUI+OR+3F61+OR+3F69+OR+3LO7+OR+3UN7+OR+3UPN+OR+3UPO+OR+3UPP)
~~~