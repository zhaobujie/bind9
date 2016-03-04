#!/bin/sh
#
# Copyright (C) 2011-2016  Internet Systems Consortium, Inc. ("ISC")
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

# $Id: tests.sh,v 1.4.154.1 2012/01/04 20:05:03 smann Exp $

SYSTEMTESTTOP=..
. $SYSTEMTESTTOP/conf.sh

DIGOPTS="+tcp +noadd +nosea +nostat +noquest +nocomm +nocmd"
DIGCMD="$DIG $DIGOPTS @10.53.0.2 -p 5300"
RNDCCMD="$RNDC -s 10.53.0.2 -p 9953 -c ../common/rndc.conf"

status=0

echo "I:preparing"
ret=0
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END || ret=1
server 10.53.0.2
zone nil.
update add text1.nil. 600 IN TXT "addition 1"
send
zone other.
update add text1.other. 600 IN TXT "addition 1"
send
END
[ -s ns2/nil.db.jnl ] || ret=1
[ -s ns2/other.db.jnl ] || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:rndc freeze"
$RNDCCMD freeze | sed 's/^/I:ns2 /'

echo "I:checking zone was dumped"
ret=0
grep "addition 1" ns2/nil.db > /dev/null 2>&1 || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking journal file is still present"
ret=0
[ -s ns2/nil.db.jnl ] || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking zone not writable"
ret=0
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END && ret=1
server 10.53.0.2
zone nil.
update add text2.nil. 600 IN TXT "addition 2"
send
END

$DIGCMD text2.nil. TXT | grep 'addition 2' >/dev/null && ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:rndc thaw"
$RNDCCMD thaw | sed 's/^/I:ns2 /'

echo "I:checking zone now writable"
ret=0
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END || ret=1
server 10.53.0.2
zone nil.
update add text3.nil. 600 IN TXT "addition 3"
send
END
$DIGCMD text3.nil. TXT | grep 'addition 3' >/dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:rndc sync"
ret=0
$RNDCCMD sync nil | sed 's/^/I:ns2 /'

echo "I:checking zone was dumped"
ret=0
grep "addition 3" ns2/nil.db > /dev/null 2>&1 || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking journal file is still present"
ret=0
[ -s ns2/nil.db.jnl ] || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking zone is still writable"
ret=0
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END || ret=1
server 10.53.0.2
zone nil.
update add text4.nil. 600 IN TXT "addition 4"
send
END

$DIGCMD text4.nil. TXT | grep 'addition 4' >/dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:rndc sync -clean"
ret=0
$RNDCCMD sync -clean nil | sed 's/^/I:ns2 /'

echo "I:checking zone was dumped"
ret=0
grep "addition 4" ns2/nil.db > /dev/null 2>&1 || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking journal file is deleted"
ret=0
[ -s ns2/nil.db.jnl ] && ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking zone is still writable"
ret=0
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END || ret=1
server 10.53.0.2
zone nil.
update add text5.nil. 600 IN TXT "addition 5"
send
END

$DIGCMD text4.nil. TXT | grep 'addition 4' >/dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking other journal files not removed"
ret=0
[ -s ns2/other.db.jnl ] || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:cleaning all zones"
$RNDCCMD sync -clean | sed 's/^/I:ns2 /'

echo "I:checking all journals removed"
ret=0
[ -s ns2/nil.db.jnl ] && ret=1
[ -s ns2/other.db.jnl ] && ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking that freezing static zones is not allowed"
ret=0
$RNDCCMD freeze static 2>&1 | grep 'not dynamic' > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking that journal is removed when serial is changed before thaw"
ret=0
sleep 1
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END || ret=1
server 10.53.0.2
zone other.
update add text6.other. 600 IN TXT "addition 6"
send
END
[ -s ns2/other.db.jnl ] || ret=1
$RNDCCMD freeze other 2>&1 | sed 's/^/I:ns2 /'
serial=`awk '$3 == "serial" {print $1}' ns2/other.db`
newserial=`expr $serial + 1`
sed s/$serial/$newserial/ ns2/other.db > ns2/other.db.new
echo 'frozen TXT "frozen addition"' >> ns2/other.db.new
mv -f ns2/other.db.new ns2/other.db
$RNDCCMD thaw 2>&1 | sed 's/^/I:ns2 /'
sleep 1
[ -f ns2/other.db.jnl ] && ret=1
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END || ret=1
server 10.53.0.2
zone other.
update add text7.other. 600 IN TXT "addition 7"
send
END
$DIGCMD text6.other. TXT | grep 'addition 6' >/dev/null || ret=1
$DIGCMD text7.other. TXT | grep 'addition 7' >/dev/null || ret=1
$DIGCMD frozen.other. TXT | grep 'frozen addition' >/dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking that journal is kept when ixfr-from-differences is in use"
ret=0
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END || ret=1
server 10.53.0.2
zone nil.
update add text6.nil. 600 IN TXT "addition 6"
send
END
[ -s ns2/nil.db.jnl ] || ret=1
$RNDCCMD freeze nil 2>&1 | sed 's/^/I:ns2 /'
serial=`awk '$3 == "serial" {print $1}' ns2/nil.db`
newserial=`expr $serial + 1`
sed s/$serial/$newserial/ ns2/nil.db > ns2/nil.db.new
echo 'frozen TXT "frozen addition"' >> ns2/nil.db.new
mv -f ns2/nil.db.new ns2/nil.db
$RNDCCMD thaw 2>&1 | sed 's/^/I:ns2 /'
sleep 1
[ -s ns2/nil.db.jnl ] || ret=1
$NSUPDATE -p 5300 -k ns2/session.key > /dev/null 2>&1 <<END || ret=1
server 10.53.0.2
zone nil.
update add text7.nil. 600 IN TXT "addition 7"
send
END
$DIGCMD text6.nil. TXT | grep 'addition 6' >/dev/null || ret=1
$DIGCMD text7.nil. TXT | grep 'addition 7' >/dev/null || ret=1
$DIGCMD frozen.nil. TXT | grep 'frozen addition' >/dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

# temp test
echo "I:dumping stats"
$RNDCCMD stats
echo "I: verifying adb records in named.stats"
grep "ADB stats" ns2/named.stats > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:test using second key"
ret=0
$RNDC -s 10.53.0.2 -p 9953 -c ns2/secondkey.conf status > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:test 'rndc dumpdb' on a empty cache"
ret=0
$RNDC -s 10.53.0.3 -p 9953 -c ../common/rndc.conf dumpdb > /dev/null || ret=1
for i in 1 2 3 4 5 6 7 8 9
do
	tmp=0
	grep "Dump complete" ns3/named_dump.db > /dev/null || tmp=1
	[ $tmp -eq 0 ] && break
	sleep 1
done
[ $tmp -eq 1 ] && ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:test 'rndc reload' on a zone with include files"
ret=0
grep "incl/IN: skipping load" ns2/named.run > /dev/null && ret=1
loads=`grep "incl/IN: starting load" ns2/named.run | wc -l`
[ "$loads" -eq 1 ] || ret=1
$RNDC -s 10.53.0.2 -p 9953 -c ../common/rndc.conf reload > /dev/null || ret=1
for i in 1 2 3 4 5 6 7 8 9
do
    tmp=0
    grep "incl/IN: skipping load" ns2/named.run > /dev/null || tmp=1
    [ $tmp -eq 0 ] && break
    sleep 1
done
[ $tmp -eq 1 ] && ret=1
touch ns2/static.db
$RNDC -s 10.53.0.2 -p 9953 -c ../common/rndc.conf reload > /dev/null || ret=1
for i in 1 2 3 4 5 6 7 8 9
do
    tmp=0
    loads=`grep "incl/IN: starting load" ns2/named.run | wc -l`
    [ "$loads" -eq 2 ] || tmp=1
    [ $tmp -eq 0 ] && break
    sleep 1
done
[ $tmp -eq 1 ] && ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with hmac-md5"
ret=0
$RNDC -s 10.53.0.4 -p 9951 -c ns4/key1.conf status > /dev/null 2>&1 || ret=1
for i in 2 3 4 5 6
do
        $RNDC -s 10.53.0.4 -p 9951 -c ns4/key${i}.conf status > /dev/null 2>&1 && ret=1
done
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with hmac-sha1"
ret=0
$RNDC -s 10.53.0.4 -p 9952 -c ns4/key2.conf status > /dev/null 2>&1 || ret=1
for i in 1 3 4 5 6
do
        $RNDC -s 10.53.0.4 -p 9952 -c ns4/key${i}.conf status > /dev/null 2>&1 && ret=1
done
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with hmac-sha224"
ret=0
$RNDC -s 10.53.0.4 -p 9953 -c ns4/key3.conf status > /dev/null 2>&1 || ret=1
for i in 1 2 4 5 6
do
        $RNDC -s 10.53.0.4 -p 9953 -c ns4/key${i}.conf status > /dev/null 2>&1 && ret=1
done
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with hmac-sha256"
ret=0
$RNDC -s 10.53.0.4 -p 9954 -c ns4/key4.conf status > /dev/null 2>&1 || ret=1
for i in 1 2 3 5 6
do
        $RNDC -s 10.53.0.4 -p 9954 -c ns4/key${i}.conf status > /dev/null 2>&1 && ret=1
done
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with hmac-sha384"
ret=0
$RNDC -s 10.53.0.4 -p 9955 -c ns4/key5.conf status > /dev/null 2>&1 || ret=1
for i in 1 2 3 4 6
do
        $RNDC -s 10.53.0.4 -p 9955 -c ns4/key${i}.conf status > /dev/null 2>&1 && ret=1
done
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with hmac-sha512"
ret=0
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf status > /dev/null 2>&1 || ret=1
for i in 1 2 3 4 5
do
        $RNDC -s 10.53.0.4 -p 9956 -c ns4/key${i}.conf status > /dev/null 2>&1 2>&1 && ret=1
done
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing automatic zones are reported"
ret=0
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf status > rndc.status || ret=1
grep "number of zones: 198 (196 automatic)" rndc.status > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with null command"
ret=0
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with unknown control channel command"
ret=0
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf obviouslynotacommand >/dev/null 2>&1 && ret=1
# rndc: 'obviouslynotacommand' failed: unknown command
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with querylog command"
ret=0
# first enable it with querylog on option
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf querylog on >/dev/null 2>&1 || ret=1
# query for builtin and check if query was logged
$DIG @10.53.0.4 -p 5300 -c ch -t txt foo12345.bind > /dev/null || ret 1
grep "query logging is now on" ns4/named.run > /dev/null || ret=1
grep "query: foo12345.bind CH TXT" ns4/named.run > /dev/null || ret=1
# toggle query logging and check again
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf querylog > /dev/null 2>&1 || ret=1
# query for another builtin zone and check if query was logged
$DIG @10.53.0.4 -p 5300 -c ch -t txt foo9876.bind > /dev/null || ret 1
grep "query logging is now off" ns4/named.run > /dev/null || ret=1
grep "query: foo9876.bind CH TXT" ns4/named.run > /dev/null && ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc nta time limits"
ret=0
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf nta -l 2h nta1.example 2>&1 | grep "Negative trust anchor added" > /dev/null || ret=1
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf nta -l 1d nta2.example 2>&1 | grep "Negative trust anchor added" > /dev/null || ret=1
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf nta -l 1w nta3.example 2>&1 | grep "Negative trust anchor added" > /dev/null || ret=1
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf nta -l 8d nta4.example 2>&1 | grep "NTA lifetime cannot exceed one week" > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

for i in 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288
do
	echo "I:testing rndc buffer size limits (size=${i})"
	ret=0
	$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf testgen ${i} 2>&1 > rndc.output || ret=1
	actual_size=`./gencheck rndc.output`
	if [ "$?" = "0" ]; then
	    expected_size=`expr $i + 1`
	    if [ $actual_size != $expected_size ]; then ret=1; fi
	else
	    ret=1
	fi

	if [ $ret != 0 ]; then echo "I:failed"; fi
	status=`expr $status + $ret`
done

echo "I:testing rndc -r (show result)"
ret=0
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf -r testgen 0 2>&1 > rndc.output || ret=1
grep "ISC_R_SUCCESS 0" rndc.output > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:testing rndc with a token containing a space"
ret=0
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf -r flush '"view with a space"' 2>&1 > rndc.output || ret=1
grep "not found" rndc.output > /dev/null && ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:test 'rndc reconfig' with a broken config"
ret=0
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf reconfig > /dev/null || ret=1
sleep 1
mv ns4/named.conf ns4/named.conf.save
echo "error error error" >> ns4/named.conf
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf reconfig > rndc.output 2>&1 && ret=1
grep "rndc: 'reconfig' failed: unexpected token" rndc.output > /dev/null || ret=1
mv ns4/named.conf.save ns4/named.conf
sleep 1
$RNDC -s 10.53.0.4 -p 9956 -c ns4/key6.conf reconfig > /dev/null || ret=1
sleep 1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:test read-only control channel access"
ret=0
$RNDC -s 10.53.0.5 -p 9953 -c ../common/rndc.conf status > /dev/null 2>&1 || ret=1
$RNDC -s 10.53.0.5 -p 9953 -c ../common/rndc.conf nta -dump > /dev/null 2>&1 || ret=1
$RNDC -s 10.53.0.5 -p 9953 -c ../common/rndc.conf reconfig > /dev/null 2>&1 && ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:test rndc status shows running on"
ret=0
$RNDC -s 10.53.0.5 -p 9953 -c ../common/rndc.conf status > rndc.output /dev/null 2>&1 || ret=1
grep "^running on " rndc.output > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

exit $status
