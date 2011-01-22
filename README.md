# Timber

A coldfusion logging connector to the popular timber open source log server

## About Timber
------------------------
Timber is a cloud logging service that allows you to post data you wish to log via HTTP for enhanced collaboration, viewing, navigation, and notifcation.  It is unique in that it allows for data to be sent in a structured format and it will store that structure for better navigation and inspection.  This allows you to filter logs based on dot notation searching.  Another benefit is that it provides a clearer view of the data you sent.

One advanced feature that sets us apart is the creation of "fingerprints"  Error fingerprints are hashes of error details we create automatically that aim to identify errors uniquely and group them logically based on fingerprint.  Fingerprints can be overridden which can be useful in grouping other types of login formation.  An example of this might be say new enrollments to a website, nightly metrics, etc, where you would want to essentially "tag" the entry for grouping purposes.

## About CFTimber
-------------------------
This connector makes it easy to start sending information into Timber.  It will build and submit the structured JSON for you.  It san be used anywhere you might use cflog() and can also be used in cfcatch and error tempates.  Below are some examples.

## USAGE:

### Init timber
	
	<cfset timber = createObject("component","com.timber").init(appkey="<appkey>)>

### Log something simple

	<cfset timber.log("Cloud Logging FTW")>

### Log Errors (use this in the error template you specified in Application.cfc)

	<cfset timber.log(error)>

### Log CFCATCH details
	<cftry>
		<cfset err = an_error>
		<cfcatch>
			<cfset timber.log(cfcatch)>
		</cfcatch>
	</cftry>

## ADVANCED USAGE

### Log some key/value pairs, include the scopes too (defaults to session,cgi,request,form,url)
	<cfset timber.log(title="The Title of your log entry",mykey="myval",yourkey="yourval",includescopes="true")>

### Log Errors and include the full stack trace and default scopes
	<cfset timber.log(detail=error,includetrace=true,includescopes=true)>

### Log CFCATCH details, include only the url and form scopes, override the default fingerprint with "badEnrollData"
	<cftry>
		<cfset err = an_error>
		<cfcatch>
			<cfset timber.log(detail=cfcatch,includescopes=true,scopes="url,form",fingerprint="badEnrollData")>
		</cfcatch>
	</cftry>
