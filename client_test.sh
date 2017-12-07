#!/bin/bash

assert ()
{
  E_PARAM_ERR=98
  E_ASSERT_FAILED=99


  if [ -z "$2" ]
  then
    return $E_PARAM_ERR
  fi

  lineno=$2

  if [ ! $1 ] 
  then
    echo "Assertion failed:  \"$1\""
    echo "File \"$0\", line $lineno"
    pkill camlsyncserver
    exit 0
  fi  
}
mkdir test_boi
cd test_boi
mkdir client_boi
mkdir client_boi2
mkdir server_boi
cd server_boi
camlsyncserver init
camlsyncserver 2>&1 & > nohup.out
cd ../client_boi
camlsync init
# check if init is successful
assert "-e .config" $LINENO
assert "-e .caml_sync" $LINENO
echo "123" >> 1.txt
camlsync

cd ../client_boi2
camlsync init
assert "-e .config" $LINENO
assert "-e .caml_sync" $LINENO
assert "-e 1.txt" $LINENO

# sync remove
rm 1.txt
camlsync
cd ../client_boi
camlsync
assert "! -e 1.txt" $LINENO

# at client boi 1
# sync multiple files
echo "1" >> 1.txt
echo "2" >> 2.txt
echo "3" >> 3.txt
touch hello.txt
camlsync
cd ../client_boi2
camlsync
assert "-e 1.txt" $LINENO
assert "-e 2.txt" $LINENO
assert "-e 3.txt" $LINENO
assert "-e hello.txt"$LINENO

# test checkout 
rm 1.txt
rm 2.txt
assert "! -e 1.txt" $LINENO
assert "! -e 2.txt" $LINENO
camlsync checkout
assert "-e 1.txt" $LINENO
assert "-e 2.txt" $LINENO
echo "hello boi" >> 4.txt
echo "bruh" >> 1.txt
assert "-e 4.txt" $LINENO
camlsync checkout
assert "$(cat 1.txt)=1" $LINENO

# test status
assert [ "$(camlsync status)"=="working directory clean" ] $LINENO
rm 1.txt
assert [ "$(camlsync status)"=="deleted: 1.txt" ] $LINENO
camlsync checkout
echo "bruh" >> 1.txt
assert [ "$(camlsync status)"=="modified: 1.txt" ] $LINENO



echo All Tests Passed!!!!!!!
pkill camlsyncserver
rm -rf test_boi
