####DEFAULT configuration. Files as provided in the CorGAT main folder
$fss=13468;
%conf=(
"genetic"=>"genetic_code",
"genome"=>"GCF_009858895.2_ASM985889v3_genomic.fna",
"annot"=>"annot_table.pl",
"hyphy"=>"hyphy.csv",
"AF"=>"AFdataJune.csv",
"MFE"=>"MFE_annot.csv",
"EPI"=>"IEDB_epitopes_update.csv",
"spike"=>"mutationSpikeTable.csv",
"geography"=>"regions.txt",
"month"=>"May2021,June2021,Jul2021,Aug2021",
"increase"=>"increasing",
"decrease"=>"decreasing",
"range"=>"ranges",
"uniprot"=>"UniprotTableNew.csv",
"scores"=>"consAndShapeWangNA0.csv",
"affinity"=>"affinityRBD.csv",
"domains"=>"domainUCSC.txt"
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

$spike=$conf{"spike"};
die("need annotation of spike mutations in the current folder\n") unless -e $spike;
open(IN,$spike);
%spikeData=();
while(<IN>)
{
	($mut,$domain,$type,$count1,$count2,$impact,@papers)=(split(/\t/));
	$spike{$mut}="$domain $impact" #if $impact eq "high";
}

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
%increase=%{read_feq($conf{"increase"},$conf{"geography"},$conf{"month"},"count")};
%decrease=%{read_feq($conf{"decrease"},$conf{"geography"},$conf{"month"},"count")};
%ranges=%{read_feq($conf{"range"},$conf{"geography"},$conf{"month"},"report")};
%uniPR=%{read_unipr($conf{"uniprot"})};
%scores=%{read_scores($conf{"scores"})}; #funziona
%affinity=%{read_affinity($conf{"affinity"})}; #funziona
%domains=%{read_domains($conf{"domains"})}; #funziona

#foreach $change (keys %increase)
#{
#	print "$change $increase{$change}\n";
#}
#die();


#foreach $protein (keys %uniPR)
#{
#	next unless $protein eq "spike";
#	foreach $start (sort{$a<=>$b} keys %{$uniPR{$protein}})
#	{
#		print "$protein $start $uniPR{$protein}{$start}\n";
#	}
#}
#die();

#print $uniPR{"spike"}{156} ."\n";


################################################################################################################

$var_File= $arguments{"--in"}; #shift;#""cl7.csv";#"phenetic_indels_sars_cov2.csv";
$out_File= $arguments{"--out"};
die("input file $var_File does not exist\n") unless -e $var_File;
open(IN,$var_File);
open(OUT,">$out_File");
$header=<IN>;
@header=(split(/\s+/,$header));
print OUT "POS\tREF\tALT\tannot\tAF\tEpitope\tHyphy\tMFE\tIncrease\tDecrease\tPrevalence\tUniprot\tCons\tStruct1\tStruct2\tIgG\tIgM\tSwissD\tSwissGly\tSwissClea\n";
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
	$uniprot_string="";
	$MFE_string= $MFE_data{"$pos$ref$alt"} ? $MFE_data{"$pos$ref$alt"} : "NA";
	$increase_string= $increase{$change} ? $increase{$change}  : "NA";
	$decrease_string= $decrease{$change} ?  $decrease{$change} : "NA";
	$ranges_string= $ranges{$change} ?  $ranges{$change} : "NA";
	$ranges_string=~s/\;\;//g;
	$cScore=0;
	$s1Score=0;
	$s2Score=0;
	$iggScore=0;
	$igmScore=0;
	$sD="NA";
	$sG="NA",
	$sC="NA";
	if ($scores{$pos})
	{
		@vls=@{$scores{$pos}};
		@val=@{$scores{$pos}};
		$cScore=$scores{$pos}[0];
		$s1Score=$scores{$pos}[1];
		$s2Score=$scores{$pos}[2];
		$iggScore=$scores{$pos}[3];
		$igmScore=$scores{$pos}[4];
	}
	if ($domains{$pos})
	{
		$sD=$domains{$pos}{"domain"} ? $domains{$pos}{"domain"} : "NA";
		$sG=$domains{$pos}{"glycosilation site"} ? $domains{$pos}{"glycosilation site"} : "NA";
		$sC=$domains{$pos}{"cleavage"} ? $domains{$pos}{"cleavage"} : "NA";;
	}
	#$increase_string=~s/;;//g;
	#$decrease_string=~s/;;//g;
	#$increase_string=~s/,;/;/g;
        #$decrease_string=~s/,;/;/g;

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
					$uniprot_string.=$res[3] if $res[3] ne "NA";
					if ($namegene ne "orf1ab" && $namegene ne "orf1a")
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
	$numEpi=0;
	$uniprot_string="NA" if $uniprot_string eq "";
	$epitope_string="NA" if $epitope_string eq "";
        $hyphy_string="NA" if $hyphy_string eq "";

	$epitope_string=~s/\s+/;/g;
	if ($epitope_string ne "NA")
        {
                $numEpi=(split(/\;/,$epitope_string));
        }
	#$epitope_string="EpiT:$epitope_string" unless $epitope_string eq "NA";
	$annot_string="noFunctionalElements" if $annot_string eq "";
	# numEpi->Epitope_string
	print OUT "$pos\t$ref\t$alt\t$annot_string\t$AF\t$numEpi\t$hyphy_string\t$MFE_string\t$increase_string\t$decrease_string\t$ranges_string\t$uniprot_string\t$cScore\t$s1Score\t$s2Score\t$iggScore\t$igmScore\t$sD\t$sG\t$sC\n" #if $contained==1;
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
	my $uniprot_string="NA";
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
		$spikeMUT="NA";
		$rbdMUT=0;
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
		$uniprot_string=$uniPR{$namegene}{$rel_pos} if $uniPR{$namegene}{$rel_pos};
		#return("$namegene:c.$pos_inG$ref>$alt,p.$A1$rel_pos$A2,$mod,$eff;",$hyphy_string,$epitopes_string);
		#return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff;spike:$spikeMUT;",$hyphy_string,$epitopes_string);
		if ($namegene eq "spike")
                {
                        $spikeMUT=$spike{"$A1$rel_pos$A2"} ? $spike{"$A1$rel_pos$A2"} : "no";
			$rbdMUT=$affinity{"$rel_pos$A2"}  ? $affinity{"$rel_pos$A2"} : "no";
			return("$namegene:c.$pos_inG$ref>$alt,p.$A1$rel_pos$A2,$eff;spike:$spikeMUT;affinity:$rbdMUT",$hyphy_string,$epitopes_string,$uniprot_string);
		}else{
			return("$namegene:c.$pos_inG$ref>$alt,p.$A1$rel_pos$A2,$eff;",$hyphy_string,$epitopes_string,$uniprot_string);
		}
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
			$hyphy_string=$hyphy_data{"$namegene$truncation"} if $hyphy_data{"$namegene$truncation"};
                	$epitopes_string=join(" ",@{$epi_data{"$namegene$truncation$ref_Seq"}}) if $epi_data{"$namegene$truncation$ref_Seq"};
                	$uniprot_string=$uniPR{$namegene}{$truncation} if $uniPR{$namegene}{$truncation};

			return("$namegene:c.$pos_inG$ref>$alt,p.$ref_Seq$truncation*,$eff;",$hyphy_string,$epitopes_string,$uniprot_string);
			#return("$namegene:$pos_inG,$rel_pos,$mod,Frameshift,$eff;",$hyphy_string,$epitopes_string);#\t$CDS_annot_string");
		}elsif($NSTOP_R==$NSTOP_G && $pos_Stop_T<($pos_Stop_R-$len) ){
		#	print "2\n";
			$truncation=$pos_Stop_T/3;
			$ref_Seq=substr($Tseq_R,$truncation-1,1);	
			$eff="Truncating";
			$eff.="Ins" if $ref=~/\./;
			$eff.="Del" if $alt=~/\./;
			$hyphy_string=$hyphy_data{"$namegene$truncation"} if $hyphy_data{"$namegene$truncation"};
                        $epitopes_string=join(" ",@{$epi_data{"$namegene$truncation$ref_Seq"}}) if $epi_data{"$namegene$truncation$ref_Seq"};
                        $uniprot_string=$uniPR{$namegene}{$truncation} if $uniPR{$namegene}{$truncation};

                        return("$namegene:c.$pos_inG$ref>$alt,p.$ref_Seq$truncation*,$eff;",$hyphy_string,$epitopes_string,$uniprot_string);
			#return("$namegene:$pos_inG,$rel_pos,$mod,Trunc:$truncation,$eff;",$hyphy_string,$epitopes_string);#\t$CDS_annot_string=");
		}else{
			%used_epitopes=();
			$hyphy_string="";
			$epitopes_string="";
			$uniprot_string="";
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
					$hyphy_string=$hyphy_data{"$namegene$rel_pos"} if $hyphy_data{"$namegene$rel_pos"};
                        		$epitopes_string=join(" ",@{$epi_data{"$namegene$rel_pos$Tref"}}) if $epi_data{"$namegene$rel_pos$Tref"};
                        		$uniprot_string=$uniPR{$namegene}{$rel_pos} if $uniPR{$namegene}{$rel_pos};
					$epitope_string="NA" if $epitope_string eq "";
        				$uniprot_string="NA" if $uniprot_string eq "";
					$hyphy_string="NA" if $hyphy_string eq "";
					return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff;",$hyphy_string,$epitopes_string,$uniprot_string);
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
					%usedAnnot=();
					$spikeMUT="NA";
					if (length($Tref)>1)
                                	{
                                        	@Tref=split('',$Tref);
                                	}else{
                                        	@Tref=($Tref);
                                	}
					for ($i=0;$i<=$#Tref;$i++)
					{
						$cur_res=$Tref[$i];
						$cur_pos=$rel_pos+$i;
						if ($epi_data{"$namegene$cur_res$cur_pos"})
						{
							$used_epitopes{join(' ',@{$epi_data{"$namegene$cur_pos$cur_res"}})}=1;
						}
						if ($hyphy_data{"$namegene$cur_pos"})
						{
							$hyphy_string.=$hyphy_data{"$namegene$cur_pos"} . ";" unless $usedAnnot{$hyphy_data{"$namegene$cur_pos"}};
							$usedAnnot{$hyphy_data{"$namegene$cur_pos"}}=1; 
						}
						if ($uniPR{$namegene}{$cur_pos})
						{
							#print $uniPR{$namegene}{$cur_pos}. "\n";
							$uniprot_string.=$uniPR{$namegene}{$cur_pos} . ";" unless $usedAnnot{$uniPR{$namegene}{$cur_pos}};
							$usedAnnot{$uniPR{$namegene}{$cur_pos}}=1;
						}

					}
					$Nkeys=keys %used_epitopes;
					$epitopes_string.=join(";",keys %used_epitopes) if $Nkeys>=1;
				}
				$epitope_string="NA" if $epitope_string eq "";
                                $uniprot_string="NA" if $uniprot_string eq "";
                                $hyphy_string="NA" if $hyphy_string eq "";
				#print "$Talt\n";
				if ($namegene eq "spike")
				{
					$spikeMUT = "no" if $spikeMUT eq "NA";
					return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff,spike:$spikeMUT;",$hyphy_string,$epitopes_string,$uniprot_string);
				}else{
					return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff;",$hyphy_string,$epitopes_string,$uniprot_string);
				}
				#return("$namegene:$pos_inG,$rel_pos,$mod,$Tref->$Talt,$eff;",$hyphy_string,$epitopes_string);#\t$CDS_annot_string");
			}else{
				$spikeMUT="NA";
				$Tref=(translate($Cref,\%code))[1];
				$Talt=(translate($Calt,\%code))[1];
				$eff="synonymous"  if $Tref eq $Talt;
				$eff="missense" if $Tref ne $Talt;
				$eff="stopGain" if $Talt=~/\*/;
				$eff="stopLoss" if $Tref=~/\*/ && !$Talt=~/\*/;
				%usedAnnot=();
				if (length($Tref)>1)
				{
					@Tref=split('',$Ttref);
					@Talt=split('',$Talt);
				}else{
					@Tref=($Tref);
					@Talt=($Talt);
				}
                                for ($i=0;$i<=$#Tref;$i++)
                                {
                                	$cur_res=$Tref[$i];
					$cur_alt=$Talt[$i];
                                        $cur_pos=$rel_pos+$i;
                                        if ($epi_data{"$namegene$cur_pos$cur_res"})
                                        {
                                        	$used_epitopes{join(' ',@{$epi_data{"$namegene$cur_pos$cur_res"}})}=1;
                                        }
                                        if ($hyphy_data{"$namegene$cur_pos"})
                                      	{
                                         	$hyphy_string.=$hyphy_data{"$namegene$cur_pos"} . ";" unless $usedAnnot{$hyphy_data{"$namegene$cur_pos"}};
                                                $usedAnnot{$hyphy_data{"$namegene$cur_pos"}}=1;

                                        }
					if ($uniPR{$namegene}{$cur_pos})
                                        { 
                                        	$uniprot_string.=$uniPR{$namegene}{$cur_pos} . ";" unless $usedAnnot{$uniPR{$namegene}{$cur_pos}};
                                                $usedAnnot{$uniPR{$namegene}{$cur_pos}}=1;

                                        }
					if ($namegene eq "spike")
					{
						if($spikeMUT eq "NA")
						{
							$spikeMUT=$spike{"$cur_res$cur_pos$cur_alt"} if $spike{"$cur_res$cur_pos$cur_alt"}
						}else{
							$spikeMUT.=";" . $spike{"$cur_res$cur_pos$cur_alt"} if $spike{"$cur_res$cur_pos$cur_alt"};
						}	
					}
                      		}

                                $Nkeys=keys %used_epitopes;
                                $epitopes_string.=join(";",keys %used_epitopes) if $Nkeys>=1;
				$epitope_string="NA" if $epitope_string eq "";
                                $uniprot_string="NA" if $uniprot_string eq "";
                                $hyphy_string="NA" if $hyphy_string eq "";
                                if ($namegene eq "spike")
                                {
                                        $spikeMUT="no" if $spikeMUT eq "NA";
					return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff;spike:$spikeMUT;",$hyphy_string,$epitopes_string,$uniprot_string);
				}else{
					return("$namegene:c.$pos_inG$ref>$alt,p.$Tref$rel_pos$Talt,$eff;",$hyphy_string,$epitopes_string,$uniprot_string);
				}
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
		($gene,$pos,$res,$EPIseq,$num,$HLA,$annot)=(split);
		push(@{$data{"$gene$pos$res"}},"$EPIseq,$num,$HLA,$annot");
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
			$a=~s/{//g;
			$a=~s/}//g;
			($ref,$key)=(split(/\:/,$a));
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

sub read_feq
{
        my $Ffile=$_[0];
	die("$Ffile does not exist") unless -e $Ffile;
        my $geography=$_[1];
        my $month=$_[2];
	my $mode=$_[3];
	#print "$Ffile m:$mode\n" ;
	my @Wmonths=(split(/\,/,$month));
	my %wm=();
	foreach my $wm (@Wmonths)
	{
		$wm{$wm}=1;
	}
        my %localFdata=();
        my %keepR=();
        open(IN,$geography);
        while(<IN>)
        {
                my ($region,$det)=(split())[0,1];
		#print "$region\n";
                $keepR{$region}=1;
        }
	my @rr=keys %keepR;
        open(IN,$Ffile);
        $header=<IN>;
        @months=split(/\s+/,$header);
	my @index=();
	my $match=0;
	for (my $m=1;$m<=$#months;$m++)
	{
		my $mo=$months[$m];
		if ($wm{$mo})
		{
			$match=1;
			push(@index,$m);
		}
	}
	if ($match==0)
	{
		warn("$month not in $header, or month names string is not valid. Please see the manual\n");
		warn("data from the last month in the table ($months[$index]) will be used instead\n");
		@index=(-1);
	}
	#print "@index\n";
	#print "$index\n";
	while(<IN>)
	{
		my ($af,@values)=(split(/\s+/));
		foreach my $i (@index)
		{
			my $month=$months[$i];
			#if ($i!=0 && $localFdata{$af})
			#{
			#	$localFdata{$af}.=";";
			#}
			my $data=$values[$i];
			if ($data ne "none")
			{
				my @reg=(split(/\,/,$data));
				foreach my $R (@reg)
				{
					my ($c,$v)=(split(/\:/,$R));
					if ($keepR{$c})
					{
						#if ($R ne $reg[$#reg])
						#{
						if ($mode eq "count")
						{
							$localFdata{$af}{$month}++;#.="$month:$c:$v,";
						}elsif ($mode eq "report"){
							$localFdata{$af}.="$month:$c:$v;";
						}
						#}else{
						#	$localFdata{$af}.="$month:$c:$v";
						#}
					}
				}
			}
		}
	}
	if ($mode eq "count")
	{
		my %outData=();
		foreach my $afd (keys %localFdata)
		{
			my $string="";
			foreach my $month (@Wmonths)
			{
				my $val=$localFdata{$afd}{$month} ? $localFdata{$afd}{$month} : 0;
				$string.="$month:$val;"
			}
			chop($string);
			$outData{$afd}=$string;
			#print "$afd $string\n";
		}
		return \%outData;
	}elsif ($mode eq "report"){
		return \%localFdata;
	}
}

sub read_unipr
{
	my $file=$_[0];
	die("$file does not exist") unless -e $file;
	open(IN,$file);
	my %dataPR=();
	while(<IN>)
	{
		#spike   685     686     Site    Note=Cleavage%3B by TMPRSS2 or furin;Ontology_term=ECO:0000255,ECO:0000269,ECO:0000269;evidence=ECO:0000255|HAMAP-Rule:MF_04099,ECO:0000269|PubMed:32142651,ECO:0000269|PubMed:32362314;Dbxref=PMID:32142651,PMID:32362314
		my ($protein,$start,$end,$annotT,$details)=(split(/\t/));
		$details=(split(/\;/,$details))[0];
		next if $annotT eq "Mutagenesis";
		my $Ostart=$start;
		for (;$start<=$end;$start++)
		{
			if ($dataPR{$protein}{$start})
			{
				$dataPR{$protein}{$start}.="::$annotT:$Ostart-$end:$details";
			}else{
				$dataPR{$protein}{$start}="$annotT:$Ostart-$end:$details";
			}
		}
	}
	return \%dataPR;
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

sub read_scores
{
	$scoreFile=$_[0];
	open(IN,$scoreFile);
	$header=<IN>;
	%numericData=();
	while(<IN>)
	{
		chomp();
		($pos,$conservation,$shape1,$shape2,$ig1,$ig2)=(split(/\,/));
		$numericData{$pos}=[$conservation,$shape1,$shape2,$ig1,$ig2];
	}
	return \%numericData;
}

sub read_domains
{
	$file=$_[0];
	open(IN,$file);
	$header=<IN>;
	%dom=();
	while(<IN>)
	{
		chomp();
		($ds,$start,$end,$annot,$type)=(split(/\t/));
		for (;$start<=$end;$start++)
		{
			$dom{$start}{$type}=$annot;
		}
	}
	return(\%dom);
}

sub read_affinity
{
	$afile=$_[0];
	open(IN,$afile);
	$header=<IN>;
	chomp($header);
	($start,$end,$residue,@header)=(split(/\t/,$header));
	%affinity=();
	while(<IN>)
	{
		chomp();
		($start,$end,$residue,@values)=(split());
		for ($i=0;$i<=$#values;$i++)
		{
			$aa=$header[$i];
			$affinity{"$residue$aa"}=$values[$i];
		}
	}
	return(\%affinity);
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

