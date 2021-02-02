####DEFAULT configuration. Files as provided in the CorGAT main folder
$fss=13468;
%conf=(
"genetic"=>"genetic_code",
"genome"=>"GCF_009858895.2_ASM985889v3_genomic.fna",
"annot"=>"annot_table.pl",
"hyphy"=>"hyphy.csv",
"AF"=>"af_data_new.csv",
"MFE"=>"MFE_annot.csv",
"EPI"=>"epitopes_annot.csv"
);

#PARAMETERS
%arguments=
(
"--in"=>"F",                 #F==FALSE, --multi <file> used to pass a multifasta input file
"--conf"=>"corgat.conf",     #F==FALSE, --filelist <file> used to pass a file of file names. 
#####OUTPUT file#############################################
"--out"=>"CorGAT_out.tsv"    #file #OUTPUT #tabulare
);

############################################################
# check args and config
check_arguments();
$conf_file=$arguments{"--conf"};
process_configuration_file($conf_file);

###########################################################
# read ancillary files

$gen_code=$conf{"genetic"};
die("need genetic code file in the current folder\n") unless -e $gen_code;
open(IN,$gen_code);
while(<IN>)
{
	($triplet,$oneL)=(split());
	$code{$triplet}=$oneL;
}

$genome=$conf{"genome"};
die("need reference genome file in the current folder\n") unless -e $genome;
open(IN,$genome);
while(<IN>)
{
	next if $_=~/^>/;
	chomp;
	$seq.=$_;
}
$table=$conf{"annot"};#"simple_annot_mirror";#"annot_table.pl";#sl5     29728   29768   reg
die("need detailed annotation file for SARS-CoV-2 in the current folder") unless -e $table;
open(IN,$table);
while(<IN>)
{
	chomp();
	($gene,$b1,$b2,$e,$annot,$notes)=(split(/\t/));
	$annot{$b1}{$b2}=[$gene,$e,$annot,$notes];
	#print "$gene $b1 $b2 $e $annot $notes\n";
	$len=$b2-$b1+1;
	if ($gene ne "nsp12" && $gene ne "orf1ab")
	{
		$seqgene=substr($seq,$b1-1,$len+3); #un codone inizio in più e un codone fine in più
	}else{
		$len1=$fss-$b1+1;
                $part1=substr($seq,$b1-1,$len1);
                $len2=$b2-$fss+1;
                $part2=substr($seq,$fss-1,$len2+3);
                $seqgene="$part1$part2";

	}
	$annot_seq{$gene}=$seqgene;
	$Lgenes{$gene}=length($seqgene);
	($NSTOP_G,$Tseq,$pos_Stop_R)=translate($seqgene,\%code);
	@seq_res=split('',$Tseq);
	for ($i=0;$i<=$#seq_res;$i++)
	{
		$pos=$i+1;
		$res=$seq_res[$i];
	}
}
%AF_data=%{read_simple_table($conf{"AF"})};
%MFE_data=%{read_simple_table($conf{"MFE"})};
%epi_data=%{read_epitopes($conf{"EPI"})};
%hyphy_data=%{read_hyphy($conf{"hyphy"})};

################################################################################################################

$var_File= $arguments{"--in"}; #shift;#""cl7.csv";#"phenetic_indels_sars_cov2.csv";
$out_File= $arguments{"--out"};
die("input file $var_File does not exist\n") unless -e $var_File;
open(IN,$var_File);
open(OUT,">$out_File");
$header=<IN>;
@header=(split(/\s+/,$header));
print OUT "POS\tREF\tALT\tannot\tAF\tHyphy\tEpitope\tMFE\n";
while(<IN>)
{
	($change,@pos)=(split());
	next unless $change=~/\|/;
	($pos,$allele)=(split(/_/,$change))[0,1];
	($ref,$alt)=(split(/\|/,$allele))[0,1];
	$AF=$AF_data{"$pos$ref$alt"} ? $AF_data{"$pos$ref$alt"} : 0;
	next if $alt=~/N/;
	$annot_string="";
	$contained=0;
	$epitope_string="";
	$hyphy_string="";
	$MFE_string= $MFE_data{"$pos$ref$alt"} ? $MFE_data{"$pos$ref$alt"} : "NA";
	#next if $ref eq"." || $alt eq ".";
	foreach $b1 (sort{$a<=>$b} keys %annot)
	{
		foreach $b2 (sort{$a<=>$b} keys %{$annot{$b1}})
		{
			if ($pos<=$b2 && $pos>=$b1)
			{
				$contained=1;
				$type=$annot{$b1}{$b2}[1];
				$namegene=$annot{$b1}{$b2}[0];
				if ($type eq "cds")
				{
					#print "cds";
					@res=annot_CDS($pos,$ref,$alt,$namegene);
					$annot_string.=$res[0];
					if ($namegene ne "orf1ab")
					{
						$hyphy_string.=$res[1];
						$epitope_string.=$res[2];
					}
				}else{
					$rel_pos=$pos-$b1+1;
					$annot_string.="$namegene:nc.$ref$rel_pos$alt,NA,NA;";
					$epitope_string="NA" if $epitope_string eq "";
                                	$hyphy_string="NA" if $hyphy_string eq "";
				}
			}
		}
	}
	$epitope_string=~s/\s+/;/g;
	#$epitope_string="EpiT:$epitope_string" unless $epitope_string eq "NA";
	print OUT "$pos\t$ref\t$alt\t$annot_string\t$AF\t$epitope_string\t$hyphy_string\t$MFE_string\n" #if $contained==1;
}
############################################################################################################################

sub translate
{
	@orig_seq=split('',$_[0]);
	%gen_code=%{$_[1]};
	$type="";
	$NSTOP=0;
	$Tseq="";
	$pos_Stop=0;
	for ($i=0;$i<=$#orig_seq;$i+=3)
	{
		$AA=join('',@orig_seq[$i..$i+2]);
		$res=$gen_code{$AA};
		$pos_Stop=$i if $pos_Stop ==0 && $res eq "*";
		$NSTOP++ if $res eq "*";
		$Tseq.=$res;
	}
	#print "$seq\n";
	return($NSTOP,$Tseq,$pos_Stop);
}

sub annot_CDS
{
	$pos=$_[0]; 
	$ref=$_[1]; 
	$alt=$_[2];
	$namegene=$_[3];
	my $hyphy_string="NA";
	my $epitopes_string="NA";
	#print "$pos $ref $alt $namegene\n";
	$pos_inG=$pos-$b1+1;
        $pos_inG++ if $pos >$fss && ($annot{$b1}{$b2}[0] eq "nsp12" || $annot{$b1}{$b2}[0] eq "orf1ab");
	$mod=$pos_inG%3;
	$rel_pos=int($pos_inG/3);
	$rel_pos++ if $mod !=0;
	
	if (length($ref)==1 && $ref ne "."&& $alt ne ".")
	{
	
		if ($mod ==1)
		{
			$triplet=substr($seq,$pos-1,3);
			@Bs=split('',$triplet);
			die("1\n $triplet b:$Bs[0] r:$ref") unless ($Bs[0] eq $ref);
			$Bs[0]=$alt;
		}elsif ($mod==2){
			$triplet=substr($seq,$pos-2,3);
			@Bs=split('',$triplet);
			die("2\n $triplet b:$Bs[1] r:$ref")unless ($Bs[1] eq $ref);
			$Bs[1]=$alt;
		}elsif ($mod==0){
			$triplet=substr($seq,$pos-3,3);
			@Bs=split('',$triplet);
			die("3\n $triplet b:$Bs[2] r:$ref")unless ($Bs[2] eq $ref);
			$Bs[2]=$alt;
		}
		#print "$pos_inG $relpos $mod @Bs\n";
		$Atriplet=join("",@Bs);
		$A1=$code{$triplet};
		$A2=$code{$Atriplet};
		$eff=$A1 eq $A2 ? "synonymous" : "missense";
		$eff="start_lost" if $eff eq "missense" && $rel_pos ==1;
		$eff="stopGain" if $A2 eq "*" && $A1 ne "*"; #stopG
		$eff="stopLoss" if $A1 eq "*" && $A2 ne "*"; #stopL
		$eff="S" if $A2 eq "*" && $A1 eq "*";
		$hyphy_string=$hyphy_data{"$namegene$rel_pos"} if $hyphy_data{"$namegene$rel_pos"};
		$epitopes_string=join(" ",@{$epi_data{"$namegene$rel_pos$A1"}}) if $epi_data{"$namegene$rel_pos$A1"};
		#return("$namegene:c.$pos_inG$ref>$alt,p.$A1$rel_pos$A2,$mod,$eff;",$hyphy_string,$epitopes_string);
		return("$namegene:c.$pos_inG$ref>$alt,p.$A1$rel_pos$A2,$eff;",$hyphy_string,$epitopes_string);
	}else{
		$eff="";
		$gene=$annot_seq{$namegene};
		$lgene=length($gene);
		$upstream=substr($gene,0,$pos_inG-1);
		$change=substr($gene,$pos_inG,length($ref));
		$downstream=substr($gene,$pos_inG+length($ref)-1);
		$len=length($alt);
		unless ($ref=~/\./)
		{
			$modSeq="$upstream$alt$downstream";
		}else{
			$modSeq="$upstream$alt$change$downstream";
		}
		$modSeq=~s/\.//g;

		($NSTOP_G,$Tseq_R,$pos_Stop_R)=translate($gene,\%code);
		($NSTOP_R,$Tseq_alt,$pos_Stop_T)=translate($modSeq,\%code);
		$CDS_annot_string=".";
		#print "$namegene,aa: sr:$NSTOP_G sa:$NSTOP_R psr:$pos_Stop_R psa:$pos_Stop_T\n";
		if ($NSTOP_R>$NSTOP_G && ($ref=~/\./ || $alt=~/\./))
		{
			
			$eff="frameshift";
			$eff.="Ins" if $ref=~/\./;
			$eff.="Del" if $alt=~/\./;
			$truncation=$pos_Stop_T/3;
			$ref_Seq=substr($Tseq_R,$truncation-1,1);
			return("$namegene:c.$pos_inG$ref>$alt,p.$ref_Seq$truncation*,$eff;",$hyphy_string,$epitopes_string);
			#return("$namegene:$pos_inG,$rel_pos,$mod,Frameshift,$eff;",$hyphy_string,$epitopes_string);#\t$CDS_annot_string");
		}elsif($NSTOP_R==$NSTOP_G && $pos_Stop_T<($pos_Stop_R-$len) ){
		#	print "2\n";
			$truncation=$pos_Stop_T/3;
			$ref_Seq=substr($Tseq_R,$truncation-1,1);	
			$eff="Truncating";
			$eff.="Ins" if $ref=~/\./;
			$eff.="Del" if $alt=~/\./;
			return("$namegene:c.$pos_inG$ref>$alt,p.$ref_Seq$truncation*,$eff;",$hyphy_string,$epitopes_string);
			#return("$namegene:$pos_inG,$rel_pos,$mod,Trunc:$truncation,$eff;",$hyphy_string,$epitopes_string);#\t$CDS_annot_string=");
		}else{
			%used_epitopes=();
			$hyphy_string="";
			$epitopes_string="";
			$pre="";
			$Cref=$ref;
                        $Calt=$alt;
			if ($mod==0)
			{
				$pre=substr($gene,$pos_inG-3,2);
			}elsif($mod==2){
				$pre=substr($gene,$pos_inG-2,1);
			}
			$Cref="$pre$Cref";
			$Calt="$pre$Calt";
			$post=$pos_inG+length($ref)-1;
			while (length($Cref) %3!=0)
			{
				$Cref.=substr($gene,$post,1);
				$Calt.=substr($gene,$post,1);
				$post++;
				if ($post>length($gene))
				{
					$local_gene=substr($gene,0,length($gene)-3);
					$eff="TruncatingDel";
					#print "$post\n";
					$copy_pos=$pos_inG;
					#print "$pos_inG\n";
					#print length($gene)."\n";
					#die("muoro");
					$Loc_Ref=substr($local_gene,$copy_pos);
					$Talt="-";
					while(length($Loc_Ref)%3!=0)
					{
						$copy_pos--;
						$Loc_Ref=substr($local_gene,$copy_pos);
					}
					$rel_pos=int($copy_pos/3);
        				$rel_pos++ if $mod !=0;
					$Tref=(translate($Loc_Ref,\%code))[1];
					return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff;",$hyphy_string,$epitopes_string);
					#return("$namegene:$pos_inG,$rel_pos,$mod,$Tref->$Talt,$eff;",$hyphy_string,$epitopes_string)
				}
			}
			if ($alt=~/\./ || $ref=~/\./)
			{
				$Tref="-";
				$Talt="-";
				$eff="inframe";
				if ($ref=~/\./)
				{
					$eff.="Ins";
					$Talt=(translate($Calt,\%code))[1];
					if ($Cref=~/[ACTG]{1,}/)
                                        {
                                                $Cref=~s/\.//g;
                                                $Tref=(translate($Cref,\%code))[1];
                                        }
				}
                                if ($alt=~/\./)
				{
					$eff.="Del";
					$Tref=(translate($Cref,\%code))[1];
					if ($Calt=~/[ACTG]{1,}/)
 					{
 						$Calt=~s/\.//g;
 						$Talt=(translate($Calt,\%code))[1];
 					}
				}
				if ($eff=~/Del/)
				{
					@Tref=split('',$Ttref);
					for ($i=0;$i<=$#Tref;$i++)
					{
						$cur_res=$Tref[$i];
						$cur_pos=$rel_pos+$i;
						if ($epi_data{"$namegene$cur_res$cur_pos"})
						{
							$used_epitopes{join(' ',@{$epi_data{"$namegene$cur_res$cur_pos"}})}=1;
						}
						if ($hyphy_data{"$namegene$curpos"})
						{
							$hyphy_string.=$hyphy_data{"$namegene$curpos"} . ";";
						}
					}
					$Nkeys=keys %used_epitopes;
					$epitopes_string.=join(";",keys %used_epitopes) if $Nkeys>=1;
				}
				$hyphy_string="NA" if $hyphy_string eq "";
				$epitopes_string="NA" if $epitopes_string eq "";
				#print "$Talt\n";
				return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff;",$hyphy_string,$epitopes_string);
				#return("$namegene:$pos_inG,$rel_pos,$mod,$Tref->$Talt,$eff;",$hyphy_string,$epitopes_string);#\t$CDS_annot_string");
			}else{
				$Tref=(translate($Cref,\%code))[1];
				$Talt=(translate($Calt,\%code))[1];
				$eff="synonymous"  if $Tref eq $Talt;
				$eff="missense" if $Tref ne $Talt;
				$eff="stopGain" if $Talt=~/\*/;
				$eff="stopLoss" if $Tref=~/\*/ && !$Talt=~/\*/;
				@Tref=split('',$Ttref);
                                for ($i=0;$i<=$#Tref;$i++)
                                {
                                	$cur_res=$Tref[$i];
                                        $cur_pos=$rel_pos+$i;
                                        if ($epi_data{"$namegene$cur_res$cur_pos"})
                                        {
                                        	$used_epitopes{join(' ',@{$epi_data{"$namegene$cur_res$cur_pos"}})}=1;
                                        }
                                        if ($hyphy_data{"$namegene$curpos"})
                                      	{
                                         	$hyphy_string.=$hyphy_data{"$namegene$curpos"} . ";";
                                        }
                      		}
                                $Nkeys=keys %used_epitopes;
                                $epitopes_string.=join(";",keys %used_epitopes) if $Nkeys>=1;
				$hyphy_string="NA" if $hyphy_string eq "";
                                $epitopes_string="NA" if $epitopes_string eq "";
				return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff;",$hyphy_string,$epitopes_string);
				#return("$namegene:$pos_inG,$rel_pos,$mod,$Tref->$Talt,$eff;",$hyphy_string,$epitopes_string);#\t$CDS_annot_string");
			}
		}
	}	
}


sub read_simple_table
{
	$file=$_[0];
	die ("$file does not exist") unless -e $file; 
	my %data=();
	open(IN,$file);
	while(<IN>)
	{
		($pos,$ref,$alt,$annot)=(split());
		if ($annot=~/;/)
		{
		#	$annot=(split(/\;/,$annot))[0];
		}
		$data{"$pos$ref$alt"}=$annot;
	}
	return \%data;
}

sub read_epitopes
{
	$file=$_[0];
	die("$file does not exist") unless -e $file;
	my %data=();
	open(IN,$file);
        while(<IN>)
	{
		($gene,$pos,$res,$EPIseq,$num,$HLA)=(split);
		push(@{$data{"$gene$pos$res"}},"$EPIseq,$num,$HLA");
	}
	return \%data;	
}

sub read_hyphy
{
	$file=$_[0];
	die("$file does not exist") unless -e $file;
	my %data=();
        open(IN,$file);
	%kw=("fel"=>1,"meme"=>1,"kind"=>1);#"betas"=>1);
        while(<IN>)
	{
		chomp();
		($gene,$pos,@annot)=(split(/\,/));
		foreach $a (@annot)
		{
			($ref,$key)=(split(/\:/,$a));
			$ref=~s/{//g;
			$ref=~s/}//g;
			$ref=~s/"//g;
			$key=~s/"//g;
			#print "$gene $pos $ref $key\n";
			if ($kw{$ref})
			{
				$data{"$gene$pos"}.="$ref:$key;";
			}
		}
			
	}
	return \%data;
}

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
			print_help();
                        warn("Valid arguments are @valid\n");
                        die("All those moments will be lost in time, like tears in rain.\n Time to die!\n"); #HELP.txt
                }
        }
	if ($arguments{"--in"} eq "F")
	{
		print_help();
		die("No input file provided\n");
	}
}

sub process_configuration_file
{
	$conf_file=$_[0];
	open(IN,$conf_file);
	while(<IN>)
	{
		chomp();
		($key,$value)=(split());
		unless ($conf{$key})
		{
			@valid=keys %conf;
			die("Provided a wrong value in the conf file. $key is not valid. Valid keys are: @valid\n");
		}else{
			$conf{$key}=$value;
		}
	}
}

sub print_help
{
        print "This program performs functional annotation of SARS-CoV-2 genetic variants. It can process only files created by the align.pl utility\n"; 
	print  "That is simple tabular files of phenetic profiles (presence absence of variants). Please refere to the CorGAT online docs should you\n"; 
	print  "find this explanation unclear:\n";
        print "##INPUT PARAMETERS\n\n";
        print "--in <<filename>> input file name\n";
        print "Additional (not strictly required) options are as follows:\n\n";
        print "--conf <<name>> name of a configuration file. See manual. Defaults to corgat.conf\n";
        print "\n##OUTPUT PARAMETERS\n\n";
        print "--out <<name>> Name of the output file. Defaults to CorGAT_out.tsv\n";
        print "\n##EXAMPLE:\n\n";
        print "1# input is ALIGN_out.tsv:\nperl annotate.pl --in ALIGN_out.tsv\n\n";
}

