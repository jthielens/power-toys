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

For example, a typical `p -jf axway` incantation yields (on my SuSe appliance image running standard clustering mysql, admin, and httpd):

	1         init [3]           
	. 7050    /bin/sh bin/mysqld_safe --defaults-file=$FDH/conf/mysql.conf
	. . 7088  $FDH/mysql/bin/mysqld --defaults-file=$FDH/conf/mysql.conf -
	          -basedir=$FDH/mysql --datadir=$FDH/var/db/mysql/data--user=r
	          oot --pid-file=$FDH/var/run/db.pid --skip-external-locking -
	          -port=33060 --socket=$FDH/var/tmp/mysql.sock
	. 7609    $FDH//jre/bin/java ... com.axway.st.server.httpd.ServerBootstrap
	. 8553    $FDH//jre/bin/java ...
	. 8950    $FDH//jre/bin/java ... org.apache.catalina.startup.Bootstrap start

The perl script calls `ps` underneath and tries to be smart about parsing out the interesting bits.  But YMMV, as you can see with 8553, where the TransactionManager classpath squishes the main class name off the end.

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
