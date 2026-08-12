#!/bin/sh
#script which will be called by waybar to get current context and namesapce
context=`kubectl config current-context`
namespace=`kubectl config view --minify --output 'jsonpath={..namespace}'`
output=`echo "$context|$namespace" | tr 'a-z' 'A-Z'`

# echo $output

if [[ `echo $output|grep "TEST|"` != "" ]]; then
	printf "{\"text\":\"⎈ $output\",\"class\":\"test\"}";
    # printf '{"text":"OFFICE","class":"office"}';
elif 
    [[ `echo $output|grep "OFFICE|"` != "" ]]; then
	printf "{\"text\":\"⎈ $output\",\"class\":\"office\"}";
elif 
    [[ `echo $output|grep "ADMIN@BUILDER|"` != "" ]]; then
	printf "{\"text\":\"⎈ $output\",\"class\":\"build\"}";
elif
    [[ `echo $output|grep "PRODUCTION|"` != "" ]]; then
	printf "{\"text\":\"⎈ $output\",\"class\":\"prod\"}";
elif
    [[ `echo $output|grep "SANDBOX_GKE"` != "" ]]; then
	printf "{\"text\":\"⎈ $output\",\"class\":\"prod\"}";
elif
    [[ `echo $output` == "" ]]; then
    printf '{"test":"No kubernetes available","class":"not_available"}';
fi
