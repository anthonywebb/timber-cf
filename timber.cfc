<cfcomponent displayname="Timber Logger" hint="Provides functions to log CF expceptions and log events to a timberapp.com account">

	<cfproperty name="appkey" required="yes" type="string" hint="Timber app key for this application">
	<cfproperty name="protocol" required="yes" type="string" hint="Protocol to use: either HTTP or HTTPS">
	<cfproperty name="apiversion" required="yes" type="string" hint="Version of the timber api to use">

	<!--- Instance variables --->
	<cfset this.appkey = "">
	<cfset this.protocol = "">
	<cfset this.apiversion = "">

	
	<!--- Constructor function --->
	<cffunction name="init" access="public" returntype="struct" output="false" hint="Initializes variables we need for the rest of the component">
		<cfargument name="appkey" type="string" required="true" hint="Timber app key">
		<cfargument name="secure" type="boolean" required="false" default="no" hint="If true, all calls made through HTTPS rather than HTTP">
		<cfargument name="apiversion" type="string" required="false" default="v1" hint="Version of the timber api to use">
		<cfargument name="scopes" type="string" required="false" default="session,cgi,request,form,url" hint="Scopes you wish to dump by default">
		<cfargument name="catchtypes" type="string" required="false" default="application,database,template,security,object,missingInclude,expression,lock,searchengine" hint="Helping us decipher if you are logginf a cfcatch variable">
		
		<cfset setAppKey(arguments.appkey)>
		<cfset setSecure(arguments.secure)>
		<cfset setApiVersion(arguments.apiversion)>	
		<cfset setScopes(arguments.scopes)>	
		<cfset setCatchTypes(arguments.catchtypes)>		
		
		<cfreturn this>
		
	</cffunction>
	
	<!--- Private Functions --->
	<cffunction name="dumpScopes" access="private" returntype="struct" output="false" hint="Grab and dump the scope to a struct">
		<cfset var result = structNew()>
		
		<cfloop list="#this.scopes#" index="thisScope">
			
			<cfif isDefined(thisScope)>
				<cfset result[thisScope] = evaluate(thisScope)>
			</cfif>
			
		</cfloop>

		<cfreturn result>
	</cffunction>
	
	<cffunction name="logException" access="private" returntype="struct" output="false" hint="Logs a CF exception to Timber">
		<cfargument name="exception" required="true" type="struct" hint="Error vars">
		
		<cfset var result = structNew()>
		<cfset var theUrl = "">
		<cfset var fingerprint = "">
		<cfset var hashedfingerprint = "">
		<cfset var searchresult = "">
		
		<cfset result.logged = ''>
		<cfset result.message = ''>

		<cfif StructKeyExists(arguments.exception,"RootCause")>
		
			<cfset searchResult = StructFindKey( #arguments.exception.rootCause#, "TagContext" )>
			
			<cfif arrayLen(searchResult)>
				<!--- Create a timber fingerprint by hashing the template, column, line, and type of the exception --->
				<cfset fingerprint = searchResult[1].value[1].template & searchResult[1].value[1].column & searchResult[1].value[1].line & searchResult[1].value[1].type>
				<cfset hashedfingerprint = hash(fingerprint,"SHA")>
				
				<cfset logDetail = StructNew()>
		
				<cfset logDetail.title = arguments.exception.Message>
				<cfset logDetail.fingerprint = hashedfingerprint>
				<cfset logDetail.error_template = arguments.exception.RootCause.TagContext[1].Template>
				<cfset logDetail.error_line = arguments.exception.RootCause.TagContext[1].Line>
				<cfset logDetail.error_column = arguments.exception.RootCause.TagContext[1].Column>
				<cfset logDetail.error_type = arguments.exception.RootCause.TagContext[1].Type>
				<cfset logDetail.error_detail = arguments.exception.RootCause.Detail>
				<cfset logDetail.error_query = arguments.exception.QueryString>
				<cfset logDetail.error_browser = arguments.exception.Browser>
				<cfset logDetail.error_remote = arguments.exception.RemoteAddress>
				<cfset logDetail.error_referer = arguments.exception.HTTPReferer>
				
				<cfset result.status = 'ok'>
				<cfset result.message = logDetail>
				
			<cfelse>
				<cfset result.status = 'error'>
				<cfset result.message = "Tag context was not found in this exception">
			</cfif>
		<cfelse>
			<cfset result.status = 'error'>
			<cfset result.message = "Root cause was not found in this exception">
		</cfif>

		<cfreturn result>
		
	</cffunction>
	
	
	<cffunction name="logCatch" access="private" returntype="struct" output="false" hint="Logs the details of a CFCATCH to Timber.">
		<cfargument name="exception" required="true" type="any" hint="CFCatch struct">
		
		<cfset var result = structNew()>
		<cfset var theUrl = "">
		<cfset var fingerprint = "">
		<cfset var hashedfingerprint = "">
		<cfset var searchresult = "">
		
		<cfset result.logged = ''>
		<cfset result.message = ''>
		
		<cfif StructKeyExists(arguments.exception,"Type")>
		
			<cfset searchresult = StructFindKey( #arguments.exception#, "TagContext" )>
			
			<cfif arrayLen(searchresult)>
				<!--- Create a timber fingerprint by hashing the template, column, line, and type of the exception --->
				<cfset fingerprint = searchResult[1].value[1].template & searchResult[1].value[1].column & searchResult[1].value[1].line & searchResult[1].value[1].type>
				<cfset hashedfingerprint = hash(fingerprint,"SHA")>
				
				<cfset logDetail = StructNew()>
		
				<cfset logDetail.title = arguments.exception.message>
				<cfset logDetail.fingerprint = hashedfingerprint>
				<cfset logDetail.error_line = searchResult[1].value[1].line>
				<cfset logDetail.error_column = searchResult[1].value[1].column>
				<cfset logDetail.error_type = arguments.exception.type>
				<cfset logDetail.error_detail = arguments.exception.Detail>
				<cfset logDetail.error_template = searchResult[1].value[1].template>
				
				<cfif arguments.exception.type IS "expression">
					<cfset logDetail.error_number = arguments.exception.ErrNumber>
				</cfif>
				
				<cfif arguments.exception.type IS "missingInclude">
					<cfset logDetail.error_missingfile = arguments.exception.MissingFileName>
				</cfif>
				
				<cfif arguments.exception.type IS "lock">
					<cfset logDetail.error_lockname = arguments.exception.LockName>
					<cfset logDetail.error_lockoperation = arguments.exception.LockOperation>
				</cfif>
				
				<cfif arguments.exception.type IS "custom">
					<cfset logDetail.error_errorcode = arguments.exception.ErrorCode>
				</cfif>
				
				<cfif arguments.exception.type IS "application" OR arguments.exception.type IS "custom">
					<cfset logDetail.error_extendedinfo = arguments.exception.ExtendedInfo>
				</cfif>
				
				<cfset result.status = 'ok'>
				<cfset result.message = logDetail>
				
			<cfelse>
				<cfset result.status = 'error'>
				<cfset result.message = "Tag context was not found in this catch">
			</cfif>
		<cfelse>
			<cfset result.status = 'error'>
			<cfset result.message = "Could not find exception type">
		</cfif>
		

		<cfreturn result>
		
	</cffunction>

	<!--- Public Functions --->
	
	
	<!--- ** Utility Functions ** --->
	<cffunction name="setAppKey" access="public" output="false" hint="Sets the appkey">
		<cfargument name="appkey" type="string" required="true" hint="Timber appkey">
		<cfset this.appkey = arguments.appkey>
	</cffunction>
	
	<cffunction name="getAppkey" access="public" returntype="string" output="false" hint="Get the timber appkey">
		<cfreturn this.appkey>
	</cffunction>
		
	<cffunction name="setSecure" access="public" output="false" hint="Sets the value of the 'secure' variable">
		<cfargument name="secure" type="boolean" required="true" hint="If true, all calls made through HTTPS rather than HTTP">
		
		<cfif arguments.secure>
			<cfset this.protocol = "https://">
		<cfelse>
			<cfset this.protocol = "http://">
		</cfif>
	</cffunction>

	<cffunction name="getSecure" access="public" returntype="boolean" output="false" hint="If this.protocol is HTTPS, returns true. Otherwise returns false.">
		<cfif this.protocol IS "http://">
			<cfreturn false>
		<cfelseif this.protocol IS "https://">
			<cfreturn true>
		</cfif>
	</cffunction>
	
	<cffunction name="setApiVersion" access="public" output="false" hint="Sets the version to use of the timber api">
		<cfargument name="apiversion" type="string" required="true" hint="api version">
		
		<cfset this.apiversion = arguments.apiversion>
	</cffunction>
	
	<cffunction name="getApiVersion" access="public" returntype="string" output="false" hint="Get the timber api version">
		<cfreturn this.apiversion>
	</cffunction>
	
	<cffunction name="setScopes" access="public" output="false" hint="Sets the scopes you wish to dump by default">
		<cfargument name="scopes" type="string" required="true" hint="scopes you are dumping">
		
		<cfset this.scopes = arguments.scopes>
	</cffunction>
	
	<cffunction name="getScopes" access="public" returntype="string" output="false" hint="Get scopes you are logging">
		<cfreturn this.scopes>
	</cffunction>
	
	<cffunction name="setCatchTypes" access="public" output="false" hint="Sets the scopes you wish to dump by default">
		<cfargument name="catchtypes" type="string" required="true" hint="scopes you are dumping">
		
		<cfset this.catchtypes = arguments.catchtypes>
	</cffunction>
	
	<cffunction name="getCatchTypes" access="public" returntype="string" output="false" hint="Get scopes you are logging">
		<cfreturn this.catchtypes>
	</cffunction>
	
	<cffunction name="postToTimber" access="public" returntype="struct" output="false" hint="Posts stuff to timber and returns the result">
		<cfargument name="data" required="true" type="string" hint="JSON data for this log message">
		<cfset var result = structNew()>
		
		<cfhttp url="#this.protocol#api.timberapp.com/#this.apiversion#/#this.appkey#/log" method="POST" result="thepost">
			<cfhttpparam type="header" name="content-type" value="application/json">
			<cfhttpparam type="body" value="#arguments.data#">
		</cfhttp>
		
		<cfset result.statusCode = thepost.statusCode>
		<cfset result.fileContent = thepost.fileContent>
		
		<cfreturn result>
	</cffunction>

	<!--- ** Timber Logging function ** --->
	<cffunction name="log" access="public" returntype="struct" output="false" hint="Logs a message to Timber.">
		<cfargument name="detail" required="false" default="" type="any" hint="Detail for this log message">
		<cfargument name="title" required="false" type="string" default="" hint="Title for this log message">
		<cfargument name="fingerprint" required="false" type="string" default="" hint="fingerpint for this log message">
		<cfargument name="includeScopes" required="false" type="boolean" default="false" hint="should we add on all specified scope into this log detail?">
		<cfargument name="includeTrace" required="false" type="boolean" default="false" hint="should we add the stack trace log detail?">
		
		<cfset var result = structNew()>
		<cfset var theUrl = "">
		<cfset var searchresult = "">
		
		<cfset result.logged = ''>
		<cfset result.message = ''>
			
		<cfset logDetail = StructNew()>	
		
		<!--- is this an exception they are logging? --->
		<cfif isDefined('arguments.detail.type') AND arguments.detail.type IS "coldfusion.runtime.CfErrorWrapper">
			<cfset getErrorDetail = logException(arguments.detail)>
			<cfif getErrorDetail.status IS 'ok'>
				<cfset logDetail = getErrorDetail.message>
			<cfelse>
				<cfset logDetail.error = getErrorDetail.message>
			</cfif>
			<cfset logDetail.logtype = "error"> 
	
		<!--- they must be logging a cfcatch --->
		<cfelseif isDefined('arguments.detail.type') AND listFindNoCase(this.catchtypes,arguments.detail.type)> 
			<cfset getCatchDetail = logCatch(arguments.detail)>
			<cfif getCatchDetail.status IS 'ok'>
				<cfset logDetail = getCatchDetail.message>
			<cfelse>
				<cfset logDetail.error = getCatchDetail.message>
			</cfif>
			<cfset logDetail.logtype = "cfcatch">
		
		<!--- everthing else --->
		<cfelse>
			<cfset logDetail.logtype = "general"> 
			<cfif isStruct(arguments.detail)>
				<cfset logDetail.detail = arguments.detail>
				
			<cfelseif arguments.detail IS NOT ''>
				<cfset logDetail.detail = arguments.detail>
			
			</cfif>
			
			<cfif arguments.fingerprint IS NOT ''>
				<cfset logDetail.fingerprint = arguments.fingerprint>
			</cfif>
			
			<cfif arguments.fingerprint IS NOT ''>
				<cfset logDetail.title = arguments.title>
			</cfif>
			
			<!--- loop over the arguments and add each one to the log detail --->
			<cfloop list="#StructKeyList(ARGUMENTS)#" index="imhere">
				<cfset thefullfield = "arguments.#imhere#">
				<cfset thisVal = evaluate(thefullfield)>
				<cfset fieldName = "#replace(imhere,'.','_','ALL')#">
				<cfif len(thisVal) AND NOT listFindNoCase("DETAIL,TITLE,FINGERPRINT,INCLUDESCOPES",imhere)>
					<cfset logDetail[#ucase(fieldName)#] = thisVal>
				</cfif>
			</cfloop>
		
		</cfif>
		
		<!--- including scopes is something optional (and FALSE by default) --->
		<cfif arguments.includeScopes>
			<cfset logDetail.scopes = dumpScopes()>
		</cfif>
		
		<!--- including the entire stack trace is something optional (and FALSE by default) --->
		<cfif arguments.includeTrace AND isDefined('arguments.detail.stacktrace')>
			<cfset logDetail.stacktrace = arguments.detail.stacktrace>
		</cfif>
		
		<cfset theData = SerializeJSON(logDetail)>
		<cfset logcall = postToTimber(data=theData)>
		
		<cfset result.code = logcall.statusCode>
		<cfset result.message = logcall.fileContent>
		<cfset result.logged = theData>
		
		<cfreturn result>
		
	</cffunction>

</cfcomponent>