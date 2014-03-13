power-toys
==========

Some utilities to manage ST from the command line more easily.

## p

Process tree display, for those tired of `ps -ef | grep`.

	# p -help
	usage: p: [options] [pattern | pid]...

	options: -a               show all PIDs, including p itself
	         -f               display full command line, wrapping if necessary
	         -i               case-insensitive pattern matching
	         -j               hide java options
	         -k               show all children of selected PIDs
	         -p               print results as a PID list only
	         -u               show user ID
	         -help            display this message and exit
	         -width  number   format output for width columns (default window width)
	         -indent number   reserve indent columns for PID tree (default 24)

For example, a typical `p -jf Harmony` incantation yields (on my Vagrant ubuntu box running Harmony 5.0):

	1                       /sbin/init
	. 12356                 /home/vagrant/Harmony/../Harmony/jre/bin/java ... com.zerog.lax.LAX /home/vagrant/Harmony/Harmonyc.lax /tmp/env.properties.12356 "-s" "service"
	. . 12620               /bin/sh /home/vagrant/Harmony/webserver/AjaxSwing/bin/clientAgent.sh harmony-xxxxxx-yyyyyy 1099
	. . . 12621             /home/vagrant/Harmony/jre/bin/java ... com.cleo.lexicom.html.JVMFactory harmony-xxxxxx-yyyyyy 1099
	. . 12658               /bin/sh /home/vagrant/Harmony/webserver/AjaxSwing/bin/clientAgent.sh vlportal 1099
	. . . 12659             /home/vagrant/Harmony/jre/bin/java ... com.cleo.lexicom.html.JVMFactory vlportal 1099
	. . 12681               /bin/sh /home/vagrant/Harmony/webserver/AjaxSwing/bin/clientAgent.sh vlnavigator 1099
	. . . 12682             /home/vagrant/Harmony/jre/bin/java ... com.cleo.lexicom.html.JVMFactory vlnavigator 1099

The perl script calls `ps` underneath and tries to be smart about parsing out the interesting bits.  But YMMV if the classpath is extremely long and `ps` truncates the output.

## dump

"Smart" dumping utility, with a collection of built-in binary ASN.1 format knowledge.

```
# dump -help

usage: dump: [options] [file...]

options: -in    file,...  alternate input file specifications
         -out   file      write unformatted output to file
         -help            display this message and exit
         -oid   file      use alternate OID file (use nul to inhibit OID names)
         -oid   +file     add additional OID file
         -n               supress \n at end of output
         -q               suppress notes and errors (like 2>/dev/null)
         -v               display version history and exit

file:    All file names may carry an optional [suboptions] suffix.  Valid
         subobtions on input files are:
            offset:length      substring (both offset and length are optional)
            b64                base64 decode the file
            hex                decode from hex
            bin                treat the file as binary (default)
            asn[:type][.field] map asn.1 "type" and select "field"
         Valid suboptions on the output file are:
            b64                base64 encode the output
            hex                encode to hex
            bin                create a new binary file
            dump               format a dump report in hex and ascii
            asn[:type][,mode]  asn dump (with "type" tags or autotype)
                               use ,1 to list fields for input selectors
         Use - as a filename to supply options for STDIN or STDOUT.
         Use #xx or #xx[:len] as a filename to insert len hex xx characters

default: Default input format is:
            [b64]    if the input "looks like" base64 or has a PEM header
            [hex]    if the input is all hex characters [0-9a-fA-F]
            [bin]    otherwise
         Default output format is:
            [asn]    if the input "looks like" asn.1, otherwise
            [bin]    if the output is to a file, otherwise
            [dump]   if the output is to STDOUT

example: To base64 encode the first 1K of x.bin into x.b64:
            dump -in x.bin[:0x400] -out x.b64[b64]
         To format a dump of the end half of the resulting output file:
            dump -in x.b64[512:,b64] -out -[dump]
         Note: since -out -[dump] is the default, this could be omitted.
         To extract the public key modulus from a certificate:
            dump -in file.cer[asn:cert.tbs.pubkey.key.n.value] -out file.n[bin]
```

For example, I downloaded the TLS certificate from www.google.com with openssl s_client, sed clipped out the first certificate block, and passed it to dump:

```
# openssl s_client -showcerts -connect www.google.com:443 \
< /dev/null 2>/dev/null |
sed -ne '/BEGIN/,/END/H
   ${g;s/\(-----END CERTIFICATE-----\).*/\1/;p;}' |
dump -
    0:4:1142   sequence
    4:4:862    . tbs:sequence
    8:2:3      . . [0]
   10:2:1      . . . tbs.v:integer = 0x2 (2)
   13:2:8      . . tbs.sn:integer = 
               0000 |43D02E51 2AA5AB1B                  |*|C..Q*...        |
   23:2:13     . . tbs.alg:sequence
   25:2:9      . . . tbs.alg.id:object identifier = sha1WithRSAEncryption (1.2.840.113549.1.1.5)
   36:2:0      . . . tbs.alg.parms:null = NULL
   38:2:73     . . tbs.issuer:sequence
   40:2:11     . . . set
   42:2:9      . . . . sequence
   44:2:3      . . . . . object identifier = c (2.5.4.6)
   49:2:2      . . . . . printable string = US
   53:2:19     . . . set
   55:2:17     . . . . sequence
   57:2:3      . . . . . object identifier = o (2.5.4.10)
   62:2:10     . . . . . printable string = Google Inc
   74:2:37     . . . set
   76:2:35     . . . . sequence
   78:2:3      . . . . . object identifier = cn (2.5.4.3)
   83:2:28     . . . . . printable string = Google Internet Authority G2
  113:2:30     . . tbs.valid:sequence
  115:2:13     . . . tbs.valid.from:utc time = 140225141810Z
  130:2:13     . . . tbs.valid.to:utc time = 140526000000Z
  145:2:104    . . tbs.subject:sequence
  147:2:11     . . . set
  149:2:9      . . . . sequence
  151:2:3      . . . . . object identifier = c (2.5.4.6)
  156:2:2      . . . . . printable string = US
  160:2:19     . . . set
  162:2:17     . . . . sequence
  164:2:3      . . . . . object identifier = stateOrProvince (2.5.4.8)
  169:2:10     . . . . . utf8 string = California
  181:2:22     . . . set
  183:2:20     . . . . sequence
  185:2:3      . . . . . object identifier = locality (2.5.4.7)
  190:2:13     . . . . . utf8 string = Mountain View
  205:2:19     . . . set
  207:2:17     . . . . sequence
  209:2:3      . . . . . object identifier = o (2.5.4.10)
  214:2:10     . . . . . utf8 string = Google Inc
  226:2:23     . . . set
  228:2:21     . . . . sequence
  230:2:3      . . . . . object identifier = cn (2.5.4.3)
  235:2:14     . . . . . utf8 string = www.google.com
  251:4:290    . . tbs.pubkey:sequence
  255:2:13     . . . tbs.pubkey.alg:sequence
  257:2:9      . . . . tbs.pubkey.alg.id:object identifier = rsaEncryption (1.2.840.113549.1.1.1)
  268:2:0      . . . . tbs.pubkey.alg.parms:null = NULL
  270:5:270    . . . tbs.pubkey.key:bit string
  275:4:266    . . . + sequence
  279:4:257    . . . + . tbs.pubkey.key.n:integer = 
               0000 |00C15648 424AB9BA FE3C3156 6720D364|*|..VHBJ...<1Vg .d|
               0010 |F200C45A A9EB4ED2 D8CE0733 C3B4BD15|*|...Z..N....3....|
               0020 |65C691FF 30D475D0 DDD052ED ECA15719|*|e...0.u...R...W.|
               0030 |624FA9D9 AD6D7E69 88C31DB3 1628984A|*|bO...m~i.....(.J|
               0040 |82481380 4FBD179C E85D2ACF 924CA0A3|*|.H..O....]*..L..|
               0050 |5B665A8B 160896F7 C52F99AE FDA5686F|*|[fZ....../....ho|
               0060 |0C8BE588 DF095256 161E7E25 8ABE0D28|*|......RV..~%...(|
               0070 |C4F15DED E66FE15D 3825B6D2 4AD01205|*|..]..o.]8%..J...|
               0080 |8386139D 7AADBD0E 7412308E 5AC5650A|*|....z...t.0.Z.e.|
               0090 |F292019A 82B06DA6 8A8038B8 5876066B|*|......m...8.Xv.k|
               00A0 |0888BF75 DA77316C E09EE0C1 25314633|*|...u.w1l....%1F3|
               00B0 |AB905765 3EEF25A5 11AABA89 755270C5|*|..We>.%.....uRp.|
               00C0 |43835B5C AB1A3E9C E445F3DA 6202F2F0|*|C.[\..>..E..b...|
               00D0 |271E4822 E1C17BDD DA608133 220C48C8|*|'.H"..{..`.3".H.|
               00E0 |CFC5A985 10C8AF47 02023DDA 2E80E8AD|*|.......G..=.....|
               00F0 |0C6FB3D3 C0BF4DF3 3598F4D0 CB101486|*|.o....M.5.......|
               0100 |59                                 |*|Y               |
  540:2:3      . . . + . tbs.pubkey.key.e:integer = 0x10001 (65537)
  545:4:321    . . [3]
  549:4:317    . . . tbs.extn:sequence
  553:2:29     . . . . tbs.extn.extKeyUsage:sequence
  555:2:3      . . . . . tbs.extn.0.id:object identifier = extKeyUsage (2.5.29.37)
  560:2:22     . . . . . octet string
  562:2:20     . . . . . + tbs.extn.0.purpose:sequence
  564:2:8      . . . . . + . tbs.extn.0.purpose.0:object identifier = serverAuth (1.3.6.1.5.5.7.3.1)
  574:2:8      . . . . . + . tbs.extn.0.purpose.1:object identifier = clientAuth (1.3.6.1.5.5.7.3.2)
  584:2:25     . . . . tbs.extn.subjectAltName:sequence
  586:2:3      . . . . . tbs.extn.1.id:object identifier = subjectAltName (2.5.29.17)
  591:2:18     . . . . . octet string
  593:2:16     . . . . . + tbs.extn.1.name:sequence
  595:2:14     . . . . . + . tbs.extn.1.name.0:[2] = 
               0000 |7777772E 676F6F67 6C652E63 6F6D    |*|www.google.com  |
  611:2:104    . . . . tbs.extn.authorityInfoAccess:sequence
  613:2:8      . . . . . tbs.extn.2.id:object identifier = authorityInfoAccess (1.3.6.1.5.5.7.1.1)
  623:2:92     . . . . . octet string
  625:2:90     . . . . . + tbs.extn.2.desc:sequence
  627:2:43     . . . . . + . tbs.extn.2.desc.0:sequence
  629:2:8      . . . . . + . . tbs.extn.2.desc.0.method:object identifier = caIssuers (1.3.6.1.5.5.7.48.2)
  639:2:31     . . . . . + . . tbs.extn.2.desc.0.location:[6] = 
               0000 |68747470 3A2F2F70 6B692E67 6F6F676C|*|http://pki.googl|
               0010 |652E636F 6D2F4749 4147322E 637274  |*|e.com/GIAG2.crt |
  672:2:43     . . . . . + . tbs.extn.2.desc.1:sequence
  674:2:8      . . . . . + . . tbs.extn.2.desc.1.method:object identifier = ocsp (1.3.6.1.5.5.7.48.1)
  684:2:31     . . . . . + . . tbs.extn.2.desc.1.location:[6] = 
               0000 |68747470 3A2F2F63 6C69656E 7473312E|*|http://clients1.|
               0010 |676F6F67 6C652E63 6F6D2F6F 637370  |*|google.com/ocsp |
  717:2:29     . . . . tbs.extn.subjectKeyIdentifier:sequence
  719:2:3      . . . . . tbs.extn.3.id:object identifier = subjectKeyIdentifier (2.5.29.14)
  724:2:22     . . . . . octet string
  726:2:20     . . . . . + tbs.extn.3.subjectKeyId:octet string = 
               0000 |457E7E98 3B15FBDE 774CF0EE B0048733|*|E~~.;...wL.....3|
               0010 |9E9423A4                           |*|..#.            |
  748:2:12     . . . . tbs.extn.basicConstraints:sequence
  750:2:3      . . . . . tbs.extn.4.id:object identifier = basicConstraints (2.5.29.19)
  755:2:1      . . . . . tbs.extn.4.critical:boolean = TRUE (0xff)
  758:2:2      . . . . . octet string
  760:2:0      . . . . . + tbs.extn.4.basicConstraints:sequence
  762:2:31     . . . . tbs.extn.authorityKeyIdentifier:sequence
  764:2:3      . . . . . tbs.extn.5.id:object identifier = authorityKeyIdentifier (2.5.29.35)
  769:2:24     . . . . . octet string
  771:2:22     . . . . . + tbs.extn.5.authorityKeyId:sequence
  773:2:20     . . . . . + . tbs.extn.5.authorityKeyId.id:[0] = 
               0000 |4ADD0616 1BBCF668 B576F581 B6BB621A|*|J......h.v....b.|
               0010 |BA5A812F                           |*|.Z./            |
  795:2:23     . . . . tbs.extn.certificatePolicies:sequence
  797:2:3      . . . . . tbs.extn.6.id:object identifier = certificatePolicies (2.5.29.32)
  802:2:16     . . . . . octet string
  804:2:14     . . . . . + tbs.extn.6.policy:sequence
  806:2:12     . . . . . + . tbs.extn.6.policy.0:sequence
  808:2:10     . . . . . + . . tbs.extn.6.policy.0.id:object identifier = 1.3.6.1.4.1.11129.2.5.1
  820:2:48     . . . . tbs.extn.cRLDistributionPoints:sequence
  822:2:3      . . . . . tbs.extn.7.id:object identifier = cRLDistributionPoints (2.5.29.31)
  827:2:41     . . . . . octet string
  829:2:39     . . . . . + tbs.extn.7.dp:sequence
  831:2:37     . . . . . + . tbs.extn.7.dp.0:sequence
  833:2:35     . . . . . + . . tbs.extn.7.dp.0.name:[0]
  835:2:33     . . . . . + . . . tbs.extn.7.dp.0.name.full:[0]
  837:2:31     . . . . . + . . . . tbs.extn.7.dp.0.name.full.uri:[6] = 
               0000 |68747470 3A2F2F70 6B692E67 6F6F676C|*|http://pki.googl|
               0010 |652E636F 6D2F4749 4147322E 63726C  |*|e.com/GIAG2.crl |
  870:2:13     . alg:sequence
  872:2:9      . . alg.id:object identifier = sha1WithRSAEncryption (1.2.840.113549.1.1.5)
  883:2:0      . . alg.parms:null = NULL
  885:4:257    . sig:bit string = 
               0000 |00781691 36B433CC 23DE6E09 2AE5F25B|*|.x..6.3.#.n.*..[|
               0010 |D7F153A0 6BB8B578 7E5A34CA D3B9514A|*|..S.k..x~Z4...QJ|
               0020 |1DC89311 4A189897 AD9F6FDE 6E1C5CC9|*|....J.....o.n.\.|
               0030 |24797487 A30DF6B7 7ED571E4 BCF94287|*|$yt.....~.q...B.|
               0040 |CFBAF5C2 5A0EF5DE F07D0460 39AEE1AD|*|....Z....}.`9...|
               0050 |40E24F2E A487B662 B2E22A76 242D5633|*|@.O....b..*v$-V3|
               0060 |BA010E45 D45F17BC 284314A1 D0BEA24A|*|...E._..(C.....J|
               0070 |C5AC3B92 6CBA6CD2 305D5AE1 9D572B20|*|..;.l.l.0]Z..W+ |
               0080 |A0A2B2A5 9B51AE01 1DE24A23 C4A056EA|*|.....Q....J#..V.|
               0090 |2F318717 531CAA91 B86250EA 9ABF7EEE|*|/1..S....bP...~.|
               00A0 |1EDB7974 6BA47B8F 862818CB E281AB85|*|..ytk.{..(......|
               00B0 |088FA5A5 2688BA70 1BA689DF DD0B00AE|*|....&..p........|
               00C0 |048A0C65 5E3C9FD0 67ABDB60 18BA2397|*|...e^<..g..`..#.|
               00D0 |B059E6C9 67D4ECB1 83154F8B 263F4409|*|.Y..g.....O.&?D.|
               00E0 |0FE23447 3EA7B9F6 BF36ED73 4913E0BC|*|..4G>....6.sI...|
               00F0 |B42645BE 7F1F1C54 AC1EF78A FB5D4A7F|*|.&E....T.....]J.|
               0100 |26                                 |*|&               |
note: encoding b64 selected for google.cer
note: asn encoding selected for output
note: ASN.1 type "cert" selected for output
```

## stlist

This tool displays a list of ST instances installed on a machine, using the manifest recorded in `/etc/fd`.  In today's world of virtual machines, it is much more typical to have a single instance per machine, so it can be used best to get a quick summary of version, port, tuning, and basic user parameters using `stlist -a`.

	usage: stlist: [options]

	options: -a        show detailed information for each ST
	         -h        HTML output
	         -A alias  display ST "alias" only
	         -help     display this message and exit

and for output:

	# stlist -a
	SecureTransport [/opt/axway/SecureTransport v5.2.1 EE,SP1 b895]
	   admin   account        account (Account Manager) locked
	   admin   admin          admin (Master Administrator)
	   admin   api            ****** (Master Administrator)
	   admin   application    application (Application Manager) locked
	   admin   dbsetup        dbsetup (Database Administrator)
	   admin   setup          setup (Setup Administrator) locked
	   port    ftp            21
	   port    ftp jmx        9996
	   port    http           80 (disabled)
	   port    https          443
	   port    http shutdown  33333
	   port    http jmx       9997
	   port    as2            10080 (disabled)
	   port    as2/s          10443 (disabled)
	   port    as2 shutdown   8006
	   port    ssh            22
	   port    pesit          17617 (disabled)
	   port    pesit/s        17627 (disabled)
	   port    pesit ptcp     19617 (disabled)
	   port    pesit/s ptcp   19627 (disabled)
	   port    pesit/s cft    17637 (disabled)
	   port    pesit bounce   17647
	   port    admin          444
	   port    admin shutdown 8004
	   port    tm jmx         9999
	   port    tomcat         8005
	   port    database       33060
	   port    cluster/s      44431
	   user    alice          password
	   user    api            ******
	   user    bob            password
	   user    master         p
	   user    user1          p
	   user    user2          p
	   tune    database pool  2..100
	   tune    java memory    ..
	   tune    mdn receipts   on
	   tune    repencrypt     off
	   tune    tm ciphers     

Note that a simple cracker for default and *extremely* poor passwords is included (example above guilty as charged).  There is code in the script left over from very old ST releases, which I no longer maintain and prune out when the weeds get tall.  The last update was for 5.2, and this should be updated to use the v1.1 REST API to get port configuration instead of direct mysql queries (which won't work on LEC anyway).

## ruledump

Display TransactionManager rules in consolidated format.

	# ruledump -help
	usage: ruledump: [options]
	options: 
	         -table               print a rule table
	         -html                print rule table in html
	         -e[vent]  event,...  restrict output to requested events
	         -events              display event table
	         -help                display this message and exit
	         -1                   sort by event instead of by rule
	         -enabled             suppress (disabled) labels

For example, to see what happens (in sequence) on an `Incoming End` event, try:

	# ruledump -e 'certificate verification'
	===== Certificate Verification =====
	Pesit::PeSIT_CertPreConfig : 15
	  condition: DXAGENT_CLIENT==pesit
	  action   : .pesit.tm.agent.PesitCertPreConfigAgent() <input >output &
	  action   : ..NextPrecedence()
	Streaming::PreProcess_CertVerify : 23
	  action   : ..CertificatePreProcessAgent() <input >output
	  action   : ..CertificateBasicValidationAgent() >output
	  action   : ..NextPrecedence()
	Streaming::CertVerify : 100
	  action   : .siteminder.agents.CertVerifyAgent() >output
	  action   : ..CertificateUserStoreAgent(askPassword="false" confirmMessage="false") >output
	  action   : ..NextPrecedence()
	Streaming::PostProcess_CertVerify : 500
	  action   : ..CertificateFailureAgent() >output
	  action   : ..NextPrecedence()

You can easily see how the agents are called in order of increasing precedence, and some classname abbreviations make the output easier to read, with `com.axway.st.server` and `com.tumbleweed.st.server` being collapsed to `.` and `.tm.agents` being further collapsed into `..`.  A more complex example shows a few more features:

	# ruledump -e 'incoming end'
		===== Incoming end =====
	MDNReceipting::MDNPreReceipts : 7
	  condition: (DXAGENT_CLIENT!=as2 & !(DXAGENT_PROTOCOL==ftp-comb & DXAGENT_TARGET=~.*\.tmp) & DXAGENT_PROTOCOL!=adhoc & !DXAGENT_API_CALL=~ADHOC_PACKAGE_.*)
	  action   : ..VirtualPathMappingAgent(Impersonation="true")
	  action   : ..CalcAttrsAgent(Impersonation="true" NOASCII="true") &
	  action   : ..NextPrecedence() &
	Streaming::TimeStampAndPersist : 10
	  action   : ..TimeStamp() <input >output
	  action   : ..PersistAgent() <input >output
	Streaming::AccountContext : 11
	  condition: (DXAGENT_ACCOUNT_ID== & (DXAGENT_LOGINNAME=~.+ | DXAGENT_ACCOUNT_NAME=~.+ | DXAGENT_SCHEDULED_TYPE==subscription))
	  action   : .appframework.AccountContextAgent(Impersonation="true")
	  action   : ..NextPrecedence()
	Pesit::PesitCitValidation : 15
	  condition: DXAGENT_CLIENT==pesit
	  action   : .pesit.agent.IdfMappingAgent(Impersonation="true")
	  action   : ..NextPrecedence()
	Pesit::PesitSitValidation : 15
	  condition: (DXAGENT_CLIENT==server & DXAGENT_SITE_PROTOCOL==pesit)
	  action   : .pesit.agent.IdfMappingAgent(Impersonation="true")
	  action   : ..Continue(continue="0")
	  action   : ..NextPrecedence()
	Streaming::PathMapping : 21
	  action   : ..VirtualPathMappingAgent(Impersonation="true")
	  action   : ..PathMappingAgent(Impersonation="true")
	  action   : ..NextPrecedence()
	Streaming::ApplicationContext : 25
	  action   : .appframework.ApplicationContextAgent(Impersonation="true")
	  action   : ..ApplicationMappingAgent(Impersonation="true")
	  action   : ..NextPrecedence()
	Streaming::ReEval : 26
	  action   : ..NextPrecedence(reevaluateRules="true")
	MDNReceipting::MDNReceipts : 27
	  condition: (DXAGENT_CLIENT!=as2 & !(DXAGENT_PROTOCOL==ftp-comb & DXAGENT_TARGET=~.*\.tmp) & DXAGENT_PROTOCOL!=adhoc & !DXAGENT_API_CALL=~ADHOC_PACKAGE_.*)
	  action   : mdn.MDNAgent(Impersonation="true" SIGNING_ALIAS=mdn) &
	  action   : >2: ..NextPrecedence() &
	ArchiveAgent::ArchiveMaint(disabled) : 29
	  action   : .archivemaintapp.agents.ArchiveAgent() &
	  action   : >2: ..NextPrecedence() &
	Streaming::PesitRouting : 32
	  condition: DXAGENT_CLIENT==pesit
	  action   : ..SendToSiteAgent() &
	  action   : ..NextPrecedence() &
	Pesit::PesitSessionInitialization : 50
	  condition: DXAGENT_CLIENT==pesit
	  action   : .pesit.tm.agent.PesitSessionInitializationAgent(Impersonation="true")
	  action   : ..NextPrecedence()
	ExtStreaming::Incoming_End(disabled) : 100
	  action   : (perl) stream/stream_end.pl ()
	InStreaming::Incoming_End : 100
	  action   : ..EndAgent(Impersonation="true")
	SendToSite::SendToSite(disabled) : 99
	  action   : ..NextPrecedence()
	  action   : ..SendToSiteAgent(Impersonation="true" Site) <input >output
	AxwaySentinel::Received : 40
	  condition: DXAGENT_APPLICATION_TYPE!=SynchronyTransfer & DXAGENT_PROTOCOL!=pesit
	  action   : ..NextPrecedence()
	  action   : ..SentinelNotifierAgent(Impersonation="false" Command="com.tumbleweed.st.server.sentinel.ReceivedNotificationCommand")
	AxwaySentinel::PeSITTransferEnd : 40
	  condition: DXAGENT_PROTOCOL==pesit
	  action   : ..NextPrecedence()
	  action   : ..SentinelNotifierAgent(Impersonation="false" Command="com.tumbleweed.st.server.sentinel.PesitTransferEndedNotificationCommand")
	Streaming::PostTransmission : 31
	  action   : ..NextPrecedence(Impersonation=true) &
	  action   : .pta.agents.PostTransmissionAgent(Impersonation=true) &
	Streaming::PostProcess_Incoming_End : 30
	  action   : ..NextPrecedence()
	  action   : .appframework.ApplicationController(Impersonation="true") <input >output
	  action   : .appframework.TransferLogAgent()
	PesitTransfer::AckNoSubsc : 29
	  condition: DXAGENT_PROTOCOL==pesit
	  action   : ..NextPrecedence()
	  action   : ..Continue(continue="0")
	  action   : .pesit.tm.agent.PesitAcknowledgeSenderOnIncomingEndAgent()
	  action   : ..SentinelNotifierAgent(Impersonation="false" Command="com.tumbleweed.st.server.sentinel.SendingAckNotificationCommand")
	Streaming::TransferFinalizer : 8
	  action   : ..NextPrecedence() <input >output
	  action   : .appframework.TransferFinalizerAgent() <input >output
	
Here the semantics of `NextPrecedence` are illustrated as the event sequence counts up to 500, showing the portion of the rule up to `NextPrecedence`, with the remainder of the rule from `NextPrecedence` to the end shown as the event priorities count down.  The external `perl` agent invocation sequence is also collapsed.

For multiple event output, the `-table` and `-table -html` options are handy to produce `csv` and `html <table>` renderings.
