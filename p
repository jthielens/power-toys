#!/usr/bin/perl

#==============================================================================#
#                                o p t i o n s                                 #
#==============================================================================#

sub Getopts
   #---------------------------------------------------------------------------#
   # usage: &Getopts('a:bc@{flag}');                                           #
   #                                                                           #
   # Argument describes options as a sequence of option definitions.  Each     #
   # definition consists of an option letter or a brace-enclosed option word   #
   # followed by an optional mode character.  The mode may be : for a single-  #
   # value option ($opt_* is set to the value), @ for a multi-valued option    #
   # (values are pushed onto @opt_*), or missing for a boolean option ($opt_*  #
   # is set to 1 if the option appears).                                       #
   #                                                                           #
   # An option may also be followed by [suboption,...], in which case the      #
   # option must be invoked as -option[suboption,...] (no spaces!) or -option. #
   # In this case, $opt_* is set if any suboption is chosen, and $opt_*{*} is  #
   # set for each suboption specified.  -option by itself selects all          #
   # suboptions.                                                               #
   #                                                                           #
   # Returns 1 if no errors were encountered.  Error disgnostics are printed   #
   # to STDERR for each error encountered.                                     #
   #---------------------------------------------------------------------------#
{
   local($argumentative) = @_;
   local(%args,$arg,$mode,$_,$first,$rest);
   local($errs) = 0;
   # local($[) = 0;

   while ($argumentative) {
      $argumentative =~ /\s*(\w|\{\w+\})([:@]|\[[^\]]*\])?(.*)/;
      ($arg,$mode,$argumentative) = ($1,$2,$3);
      $arg =~ s/[{}]//g;
      if ($mode =~ /^\[/) {
         for $suboption (split (',', substr ($mode, 1, length ($mode)-2))) {
            $args{"$arg.$suboption"} = $suboption;
            print "args{$arg.$suboption} = $suboption\n" if $DEBUG;
         }
         $mode = '[';
      }
      $args{$arg} = $mode ? $mode : '';
   }

   while(@ARGV && ($_ = $ARGV[0]) =~ /^-(.)(.*)/) {
      ($first,$rest) = ($1,$2);
      local ($t) = "$first$rest";
      #--------------------------------#
      # look for -option[suboptions,,, #
      #--------------------------------#
      if ($t =~ /(\w+)(\[.*)/ && $args{$1} eq '[') {
         $first = $1;
         $rest  = $2;
      } elsif(defined $args{$t}) {
         ($first,$rest) = ($t,'');
      }
      if(defined $args{$first}) {
         if($args{$first} eq '[') {
            #-------------------------------------#
            # $first is an option with suboptions #
            #-------------------------------------#
            shift(@ARGV);
            eval "\$opt_$first = 1;";
            print "\$opt_$first = 1;\n" if $DEBUG;
            if($rest =~ /^\[/) {
               #--------------------------------------#
               # we had -option[suboptions,...]stuff: #
               #    put "stuff" back on ARGV          #
               #--------------------------------------#
               if($rest =~ /^(\[[^\]]*\])(.+)/) {
                  $rest = $1;
                  unshift(@ARGV, "-$2");
               }
            } elsif($rest eq '' && @ARGV && $ARGV[0] =~ /^\[.*\]$/) {
               #----------------------------------------------#
               # we had -option <whitespace> [suboptions,...] #
               #----------------------------------------------#
               $rest = shift(@ARGV);
            }
            if ($rest) {
               #---------------------------------#
               # we had some explicit suboptions #
               #---------------------------------#
               $rest =~ s/^\[//;
               $rest =~ s/\]$//;
               for $suboption (split (',', $rest)) {
                  next unless $suboption;
                  local (@hits) = grep (/^$first.$suboption/, keys %args);
                  if (@hits) {
                     for $hit (grep (/^$first.$suboption/, keys %args)) {
                        eval "\$opt_$first\{$args{$hit}\} = 1;";
                        print "\$opt_$first\{$args{$hit}\} = 1;\n" if $DEBUG;
                     }
                  } else {
                     ++$errs;
                     print STDERR "Unknown suboption: $first\[$suboption\]\n";
                  }
               }
            } else {
               #--------------------------------------#
               # no explicit suboptions: set them all #
               #--------------------------------------#
               for $suboption (grep (/^$first\./, keys %args)) {
                  eval "\$opt_$first\{$args{$suboption}\} = 1;";
                  print "\$opt_$first\{$args{$suboption}\} = 1;\n" if $DEBUG;
               }
            }
         } elsif($args{$first}) {
            #------------------------------------------------------#
            # $first is a single- or multi- valued option (: or @) #
            #------------------------------------------------------#
            shift(@ARGV);
            if($rest eq '') {
               if (@ARGV) {
                  $rest = shift(@ARGV);
               } else {
                  ++$errs;
                  print STDERR "Option requires a value: $first\n";
               }
            }
            if ($args{$first} eq '@') {
               my %rest;
               eval "push (\@opt_$first, split (',', \$rest));";
               print "push (\@opt_$first, $rest);\n" if $DEBUG;
            } else {
               eval "\$opt_$first = \$rest;";
               print "\$opt_$first = $rest;\n" if $DEBUG;
            }
         } else {
            #----------------------------#
            # $first is a simple Boolean #
            #----------------------------#
            eval "\$opt_$first = 1;";
            print "\$opt_$first = 1;\n" if $DEBUG;
            if($rest eq '') {
               shift(@ARGV);
            } else {
               $ARGV[0] = "-$rest";
            }
         }
      } else {
         print STDERR "Unknown option: $first\n";
         ++$errs;
         if($rest ne '') {
            $ARGV[0] = "-$rest";
         } else {
            shift(@ARGV);
         }
      }
   }
   $errs == 0;
}

#==============================================================================#
#                           p r o c e s s   l i s t                            #
#==============================================================================#

sub load_ps
{
   my ($header, $xuid, $xpid, $xppid, $xtime, $xcmd);

   open (PS, '/usr/ucb/ps -laxwww|') ||
       open (PS, '/bin/ps laxwww|') ||
       return undef;
   $header = <PS>;
   $xuid   = index ($header, '  UID');
   $xpid   = index ($header, '  PID');
   $xppid  = index ($header, ' PPID');
   $xtime  = index ($header, ' TIME')+2;
   $xcmd   = index ($header, 'COMMAND');
   while (<PS>) {
      chomp;
      my ($uid, $pid, $ppid, $cmd);
      ($uid = substr ($_, $xuid, 5)) =~ s/ //g;
      ($pid = substr ($_, $xpid, 5)) =~ s/ //g;
      ($ppid = substr ($_, $xppid, 5)) =~ s/ //g;
      $cmd = substr ($_, $xcmd+index (substr ($_, $xtime), ':'));
      $PS->{$pid}->{uid}  = $uid;
      $PS->{$pid}->{ppid} = $ppid;
      $PS->{$pid}->{cmd}  = $cmd;
   }
   for $pid (keys %$PS) {
      my $ppid = $PS->{$pid}->{ppid};
      next unless $ppid != $pid and defined $PS->{$ppid};
      push (@{$PS->{$ppid}->{cpid}}, $pid);
   }
}

sub tag_pid
{
   for $pid (@_) {
      next if $pid == $$ and not $opt_a;  # hide yourself
      &tag_kid ($pid) if $opt_k;
      while (defined $PS->{$pid} and $PS->{$pid}->{tag} != 1) {
         $PS->{$pid}->{tag} = 1;
         $pid = $PS->{$pid}->{ppid};
      }
   }
}

sub tag_kid
{
   my $pid = shift @_;
   for $cpid (@{$PS->{$pid}->{cpid}}) {
      if ($PS->{$cpid}->{tag} != 1) {
         $PS->{$cpid}->{tag} = 1;
         &tag_kid ($cpid);
      }
   }
}

sub find_cmd
{
   my $pat   = shift @_;
   my $icase = shift @_;
   my @pid;

   for $pid (keys %$PS) {
      if ($icase) {
         push (@pid, $pid) if $PS->{$pid}->{cmd} =~ /$pat/i;
      } else {
         push (@pid, $pid) if $PS->{$pid}->{cmd} =~ /$pat/;
      }
   }
   return @pid;
}

sub wrap
{
   my $s      = shift @_;
   my $width  = shift @_;
   my $indent = shift @_;

   my $block  = $width - $indent;
   my $i      = 0;
   my $rs;

   while ($i+$block < length ($s)) {
      $rs .= substr ($s, $i, $block) . "\n" . ' ' x $indent;
      $i  += $block;
   }
   $rs .= substr ($s, $i);
   return $rs;
}

sub java_cmd
{
   my $cmd    = shift @_;

   my @cmd    = split ' ', $cmd;
   if ($cmd[0] =~ m|/java$|) {
      my @java = ($cmd[0]);
      my $i    = 1;
      while ($i<$#cmd and $cmd[$i] =~ /^-/) {
         $i++ if $cmd[$i] eq '-classpath' or $cmd[$i] eq '-cp';
         $i++;
      }
      push @java, '...' if $i>1;
      push @java, @cmd[$i..$#cmd];
      return join ' ', @java;
   }
   return $cmd;
}

sub dump_ps
{
   my $pid    = shift @_;
   my $pad    = shift @_;
   my $width  = shift @_;
   my $indent = shift @_;
   my $single = shift @_;
   my $java   = shift @_;
   my $tag    = shift @_;

   return if $pid == $$ and not $opt_a;  # hide yourself
   return if $tag and not $PS->{$pid}->{tag};
   if ($opt_u) {
      print pack ('A'.($indent-8).'A8',
                  "$pad$pid",
                  getpwuid ($PS->{$pid}->{uid}) || $PS->{$pid}->{uid});
   } else {
      print pack ("A$indent", "$pad$pid");
   }
   my $cmd = $PS->{$pid}->{cmd};
   $cmd = java_cmd($cmd) if $opt_j;
   $cmd =~ s/$ENV{FDH}/\$FDH/g if defined $ENV{FDH};
   $cmd =~ s/$ENV{FILEDRIVEHOME}/\$FILEDRIVEHOME/g if defined $ENV{FILEDRIVEHOME};
   if ($single) {
      print substr ($cmd, 0, $width-$indent), "\n";
   } else {
      print &wrap ($cmd, $width, $indent), "\n";
   }
   for $cpid (sort {$a <=> $b} @{$PS->{$pid}->{cpid}}) {
      &dump_ps ($cpid, "$pad. ", $width, $indent, $single, $java, $tag);
   }
}

sub tty_width
{
   my $stty = `stty -a 2>/dev/null`;
   return $1 if $stty =~ /columns\s*=?\s*(\d+)/;
   return 80;
}

#--------------#
# Command line #
#--------------#
($PROGRAM = $0) =~ s/.*[\/\\]//;
$USAGE=<<".";

usage: $PROGRAM: [options] [pattern | pid]...

options: -a               show all PIDs, including $PROGRAM itself
         -f               display full command line, wrapping if necessary
         -i               case-insensitive pattern matching
         -j               hide java options
         -k               show all children of selected PIDs
         -p               print results as a PID list only
         -u               show user ID
         -help            display this message and exit
         -width  number   format output for width columns (default window width)
         -indent number   reserve indent columns for PID tree (default 24)
.

&Getopts ('af{help}i{indent}:jkp{width}:u')
      && !$opt_help
   || die $USAGE;

$opt_width  = $opt_width || &tty_width;
$opt_indent = $opt_indent || 24;

&load_ps;

if ($opt_p) {
   my @pid;
   for $arg (@ARGV) {
      if ($arg =~ /[^\d]/) {
         push (@pid, &find_cmd ($arg, $opt_i));
      } else {
         push (@pid, $arg);
      }
   }
   print join (' ', @pid), "\n";
} else {
   $tag = 1 if @ARGV;
   for $arg (@ARGV) {
      if ($arg =~ /[^\d]/) {
         &tag_pid (&find_cmd ($arg, $opt_i));
      } else {
         &tag_pid ($arg);
      }
   }
   my $rootpid = defined $PS->{0} ? 0 : 1;
   &dump_ps ($rootpid, '', $opt_width, $opt_indent, !$opt_f, $opt_j, $tag);
}
