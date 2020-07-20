$refile="GCF_009858895.2_ASM985889v3_genomic.fna";
unless (-e $refile)
{
	system("wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/858/895/GCF_009858895.2_ASM985889v3/GCF_009858895.2_ASM985889v3_genomic.fna.gz")==0||die("can not download the reference genome\n");
	system("gunzip GCF_009858895.2_ASM985889v3_genomic.fna.gz")==0 ||die("no gunzip");
}
@target_files=<*.fasta>;

foreach $tg (@target_files)
{
	$name=$tg;
	$name=~s/\.fasta//;
        if (-e "$name\_ref_qry.snps")
	{
		print "output file $name\_ref_qry.snps already in folder. Alignment skipped\n"
	}else{
        	system("nucmer --prefix=ref_qry $refile $tg")==0||die("no nucmer alignment\n");
        	system("show-snps -Clr ref_qry.delta > $name\_ref_qry.snps")==0||warn("no nucmer snps $tg\n");
	}
}
