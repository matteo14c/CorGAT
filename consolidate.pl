@files=<*_ref_qry.snps>;
@genomes=();
foreach $f (@files)
{
	$name=$f;
	$name=~s/_ref_qry.snps//;
	$name=~s/\.\d+//;
	push(@genomes,$name);
	open(IN,$f);
	%ldata=();
	while(<IN>)
	{
		next unless $_=~/NC_045512.2/;
                ($pos,$b1,$b2)=(split(/\s+/,$_))[1,2,3];
		$ldata{$pos}=[$b1,$b2];
	}
	$prev_pos=0;
	$prev_ref="na";
	$prev_alt="na";
	foreach $pos (sort{$a<=>$b} keys %ldata)
	{
		$dist=$pos-$prev_pos;
		if ($dist>1)
		{
			$pos_append=$prev_pos-length($prev_alt)+1;
			$dat_final{"$pos_append\_$prev_ref|$prev_alt"}{$name}=1 unless $prev_ref eq "na";
			$type{"$prev_ref|$prev_alt"}++;
			if (length($prev_ref)>1 && $prev_ref ne "na")
			{
			#	print "$pos_append\t$prev_ref\t$prev_alt\t$name\n";
				$large{$name}++;
			}
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
	$large{$name}++ if length ($prev_ref)>1 && $prev_ref ne "na";
}

@HFpos=();
$TOT=$#genomes+1;
%AF=();
print " @genomes\n";
foreach $pos (sort{$a<=>$b} keys %dat_final)
{
	$line="$pos ";
	$sum=0;
	foreach $g (@genomes)
	{
		$val=$dat_final{$pos}{$g} ? 1 : 0;
		$sum+=$val;
		$line.="$val ";
	}
	push(@HFpos,$pos) if $sum/$TOT>=0.01;
	$AF=sprintf("%.2f",($sum/$TOT)*100);
	$AF{$AF}++;
	chop($line);
	print "$line\n";
}
close(OUT);
