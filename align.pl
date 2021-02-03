use strict;

my %arguments=

(
"--multi"=>"F",         	#F==FALSE, --multi <file> used to pass a multifasta input file
"--filelist"=>"F",		#F==FALSE, --filelist <file> used to pass a file of file names. 
"--suffix"=>"F",        	#F==FALSE, --suffix <value> specifies a file name suffix. All files with that suffix will be used
"--clean"=>"T",			#BOLEAN: T: remove temporary directory of results. F: keep it. Defaule T
"--tmpdir"=>"align.tmp", 	#Name of the temporary directory. Defaults to align.tmp. 
"--refile"=>"GCF_009858895.2_ASM985889v3_genomic.fna", #Name of the reference genome 
#####OUTPUT file#############################################
"--out"=>"ALIGN_out.tsv" #file #OUTPUT #tabulare
);

############################################################
#Process input arguments and check if valid
check_arguments();
check_input_arg_valid();

###########################################################
# download the ref genome.
my $refile=$arguments{"--refile"};
unless (-e $refile)
{
	download_ref();
}

###########################################################
#create temporary dir for storing intermediate files
check_exists_command('mkdir') or die "$0 requires mkdir to create a temporary directory\n";	
check_exists_command('cp') or die "$0 requires cp to copy files to temporary directory\n";
my $TGdir=$arguments{"--tmpdir"};
if (-e $TGdir)
{
	warn ("Temporary directory $TGdir does already exist!. Please be aware that all the alignment files contained in that directory will be incorporated in the output of CorGAT!\n");
}else{
	system("mkdir $TGdir")==0||die ("can not create temporary directory $TGdir\n");
}

###########################################################
# Compile the list of files to processed.
my @target_files=();
if ($arguments{"--filelist"} ne "F")
{
# if filelist, read name. Copy files to tmpdir
	my $lfile=$arguments{"--filelist"};
	open(IN,$lfile);
	while(my $file=<IN>)
	{
		chomp($file);
		push(@target_files,"$TGdir/$file");
		system("cp $file $TGdir")==0||die("could not copy file $file to $TGdir\n");
	}
}elsif ($arguments{"--suffix"} ne "F"){
# if suffix. use all files in the present folder with suffix. Copy files to tmpdir
	my $suffix=$arguments{"--suffix"};
	check_exists_command('cp') or die "$0 requires cp to copy files to temporary directory\n";
	system("cp *.$suffix $TGdir")==0||die "$! could not copy files with the .$suffix extension to the target dir $TGdir\n";
	@target_files=<$TGdir/*.$suffix>;
}elsif ($arguments{"--multi"} ne "F"){
#if multifasta, split the files. Directly in the target folder. Compile arguments files.
	my $multifile=$arguments{"--multi"};
	@target_files=@{split_fasta($multifile,$TGdir)};
}

###########################################################
# Align
align(\@target_files,$TGdir);
my @alignments=<$TGdir/*_ref_qry.snps>;
my $out_file=$arguments{"--out"};

############################################################
# Consolidate the alignments and write output
consolidate(\@alignments,$out_file,$TGdir);


############################################################
# check if temp_files need to be removed
if ($arguments{"--clean"} eq "T")
{
	print "--clean set to T=TRUE. I am going to delete the temporary file folder $TGdir\n";
	system ("rm -rf $TGdir")==0||warn("For some reason, the temporary directory $TGdir could not be removed. Please check\n");
}


######################################################################################################################################################################
sub check_arguments
{
	my @arguments=@ARGV;
	for (my $i=0;$i<=$#ARGV;$i+=2)
	{
        	my $act=$ARGV[$i];
        	my $val=$ARGV[$i+1];
        	if (exists $arguments{$act})
        	{
                	$arguments{$act}=$val;
        	}else{
                	warn("$act: unknown argument\n");
                	my @valid=keys %arguments;
                	warn("Valid arguments are @valid\n");
                	warn("All those moments will be lost in time, like tears in rain.\n Time to die!\n"); #HELP.txt
        		print_help();
		}	
	}
}


sub download_ref
{
	print "Reference genome file, not in the current folder\n";
        print "CorGAT will try to Download the reference genome from Genbank\n";
        print "Please download this file manually, if this fails\n";
        check_exists_command('wget') or die "$0 requires wget to download the genome\nHit <<which wget>> on the terminal to check if you have wget\n";
        check_exists_command('gunzip') or die "$0 requires gunzip to unzip the genome\n";
        system("wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/858/895/GCF_009858895.2_ASM985889v3/GCF_009858895.2_ASM985889v3_genomic.fna.gz")==0||die("Could not retrieve the reference genome\n");
        system("gunzip GCF_009858895.2_ASM985889v3_genomic.fna.gz")==0 ||die("Could not unzip the reference genome");

}

sub check_exists_command {
    my $check = `sh -c 'command -v $_[0]'`;
    return $check;
}

sub check_input_arg_valid
{
	if ($arguments{"--filelist"} eq "F" && $arguments{"--suffix"} eq "F" && $arguments{"--multi"} eq "F")
	{
		print_help();
		die("No valid input mode provided. One of --filelist, --suffix or --multi needs to be provided. You set none!");
	}
	unless ($arguments{"--clean"} eq "T" || $arguments{"--clean"} eq "F")
	{
		print_help();
		die("invalid value for --clean, valid options are either T or F\n");
	}
	if ($arguments{"--multi"} ne "F")
	{
		if ($arguments{"--filelist"} ne "F" || $arguments{"--suffix"} ne "F")
		{
			print_help();
			print "Invalid options provided: --multi --filelist and --suffix are mutually exclusive\nOnly one can be T. You provided: multi->". $arguments{"--multi"} . "\tfilelist->". $arguments{"--filelist"}. "\tsuffix->". $arguments{"--suffix"}. "\n";
		die ("Please check and revise\n");
		}
	}elsif ($arguments{"--filelist"} ne "F" && $arguments{"--suffix"} ne "F"){
		print_help();
		print "Invalid options provided: --multi --filelist and --suffix are mutually exclusive\nOnly one can be T. You provided: multi->". $arguments{"--multi"} . "\tfilelist->". $arguments{"--filelist"}. "\tsuffix->". $arguments{"--suffix"}. "\n"; 
		die ("Please check and revise\n");
	}
}

sub split_fasta
{
	my $multiF=$_[0];
	die("multifasta input file does not exist $multiF\n") unless -e $multiF;
	my $tgdir=$_[1];
	my @list_files=();
	open(IN,$multiF);
	while(<IN>)
	{
		if ($_=~/^>(.*)/)
		{
			my $id=$1;
			$id=(split(/\s+/,$id))[0];
			$id=~s/\-//g;
			if ($id=~/\|(EPI.*)\|/)
			{
				$id=$1;
                	}
			$id=~s/\//\_/g;
			#for gisaid
			open(OUT,">$tgdir/$id.fasta");
			print OUT ">$id\n";
			push(@list_files,"$tgdir/$id.fasta");
		}else{
			chomp();
			print OUT;
		}
	}
	return(\@list_files);
}

sub align
{
	my @target_files=@{$_[0]};
	my $TGdir=$_[1];
	die("Target directory does not exist\n") unless -e $TGdir;
	check_exists_command('nucmer') or die "$0 requires nucmer to align genomes. Please check that nucmer is installed and can be executed. Hit <<which nucmer>> on\n your terminal to understand if the program is correctly installed";
	check_exists_command('show-snps') or die "$0 requires show-snps from the mummer package to compute polymorphic sites. Please check that show-snps is installed and can be executed. Hit <<which show-snps>> on\n your terminal to understand if the program is correctly installed";
	foreach my $tg (@target_files)
	{
        	my $name=$tg;
		chomp($name);
        	$name=~s/\.fasta//;
        	$name=~s/\.fna//;
        	$name=~s/\.fa//;    
		if (-e "$TGdir/$name\_ref_qry.snps")
        	{
                	print "output file $name\_ref_qry.snps already in folder. Alignment skipped\n"
        	}else{
                	system("nucmer --prefix=ref_qry $refile $tg")==0||die("no nucmer alignment\n");
                	system("show-snps -Clr ref_qry.delta > $name\_ref_qry.snps")==0||warn("no nucmer snps $tg\n");
        	}
	}
}

sub consolidate
{
	my @files=@{$_[0]};
	my $out_file=$_[1];
	my $dir_prefix=$_[2];;	
	my @genomes=();
	my %dat_final=();
	foreach my $f (@files)
	{
        	my $name=$f;
        	$name=~s/_ref_qry.snps//;
		$name=~s/$dir_prefix\///;
        	push(@genomes,$name);
        	open(IN,$f);
        	my %ldata=();
        	while(<IN>)
        	{
                	next unless $_=~/NC_045512.2/;
                	my ($pos,$b1,$b2)=(split(/\s+/,$_))[1,2,3];
                	$ldata{$pos}=[$b1,$b2];
        	}
        	my $prev_pos=0;
		my $pos_append=0;
        	my $prev_ref="na";
        	my $prev_alt="na";
        	foreach my $pos (sort{$a<=>$b} keys %ldata)
        	{
                	my $dist=$pos-$prev_pos;
                	if ($dist>1)
                	{
                        	$pos_append=$prev_pos-length($prev_alt)+1;
                        	$dat_final{"$pos_append\_$prev_ref|$prev_alt"}{$name}=1 unless $prev_ref eq "na";
                        	$prev_ref=$ldata{$pos}[0];
                        	$prev_alt=$ldata{$pos}[1];
                	}else{
                        	$prev_ref.=$ldata{$pos}[0];
                        	$prev_alt.=$ldata{$pos}[1];
                	}
                	$prev_pos=$pos;
        	}
        	$pos_append=$prev_pos-length($prev_alt)+1;
        	$dat_final{"$pos_append\_$prev_ref|$prev_alt"}{$name}=1 if $prev_ref ne "na";
	}
	open(OUT,">$out_file");
	my $TOT=$#genomes+1;
	my %AF=();
	print OUT " @genomes\n";
	foreach my $pos (sort{$a<=>$b} keys %dat_final)
	{
        	my $line="$pos ";
        	my $sum=0;
        	foreach my $g (@genomes)
        	{
                	my $val=$dat_final{$pos}{$g} ? 1 : 0;
                	$sum+=$val;
                	$line.="$val ";
        	}
        	chop($line);
        	print OUT "$line\n";
	}
	close(OUT);
}


sub print_help
{
	print "This utility can be used to 1) download the reference SARS-CoV-2 genome from Genbank and 2) align it with a collection\n"; 
	print "of SARS-CoV-2 genomes. And finally 3)Call/identify genomic variants.  On any *nix based system the script should be\n"; 
	print "completely capable to download the reference genome by itself.  Please download the genome yourself if this fails.\n"; 
	print "Input genomes, to be aligned to the reference, can be provided by means of 3 mutually exclusive (as in only one should be set)\n";
	print "parameters:\n";
	print "##INPUT PARAMETERS\n\n";
	print "--multi <<filename>>\tprovides a multifasta of genome sequences\n";
	print "--suffix <<text>>\tspecifies an extension. All the files with that extension in the current folder will be uses\n";
	print "--listfile <<filename>>\tspecifies a file containing a list of file names. All files need to be in the current folder\n";
	print "\nTo run the program you MUST provide one of the above options. Please notice that for --suffix and --listfile ,all\n";
	print "files need to be in the current folder.\n\nAdditional (not strictly required) options are as follows:\n\n";
	print "--tmpdir <<name>>\tname of a temporary directory. All intermediate files are saved there. Defaults to align.tmp\n";
	print "--clean <<T/F>>\t\tif T, tmpdir is delete. Otherwise it is not.\n";
	print "--refile <<file>>\tname of the reference genome file. Defaults to the name of the reference assembly of the SARS-CoV-2 genome\n";
	print "		        in Genbank. Do not change uless you have a very valid reason\n";
	print "\n##OUTPUT PARAMETERS\n\n";
	print "--out <<name>>\tName of the output file. Defaults to ALIGN_out.tsv\n"; 
	print "\n##EXAMPLES:\n\n";
	print "1# input is multi-fasta (apollo.fa):\nperl align.pl --multi apollo.fa\n\n";
	print "2# use all .fasta files from the current folder:\nperl align.pl --suffix fasta\n\n";
	print "3# use a file of file names (lfile):\n perl align.pl --filelist lfile\n\n";
}
