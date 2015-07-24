<p:declare-step version="1.0" 
	name="bot"
	type="twitter:bot"
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:twitter="tag:conaltuohy.com,2015:twitter"
	xmlns:digitalnz="tag:conaltuohy.com,2015:digitalnz"
	xmlns:paperspast="tag:conaltuohy.com,2015:paperspast"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:html="http://www.w3.org/1999/xhtml">
	
	<p:input port="parameters" kind="parameter"/>
	<p:output port="result"/>
	
	<!-- get a page containing an illustration from 100 years ago -->
	<paperspast:on-this-day name="centenary" content-type="illustration" years-ago="100"/>
	<!-- download the first image from that page -->
	<paperspast:get-image>
		<p:with-option name="href" select="(//html:img[@class='veridianimage'])[1]/@src"/>
	</paperspast:get-image>
	<!-- upload it to Twitter -->
	<twitter:upload-media/>
	<!-- construct a tweet that references the image uploaded to Twitter -->
	<p:group>
		<p:variable name="media-id" select="substring-after(substring-before(/c:body, ','), ':')"/>
		<p:variable name="headline" select="/html:html/html:head/html:meta[@name='newsarticle_headline']/@content">
			<p:pipe step="centenary" port="result"/>
		</p:variable>
		<p:variable name="citation" select="
			concat(
				' - ',
				/html:html/html:head/html:meta[@name='newsarticle_publication']/@content,
				' #100years '
			)
		">
			<p:pipe step="centenary" port="result"/>
		</p:variable>
		<p:variable name="uri" select="/html:html/@xml:base">
			<p:pipe step="centenary" port="result"/>
		</p:variable>
		<p:variable name="status" select="
			concat(
				substring(
					$headline, 1, 140 - string-length($citation) - 21
				),
				$citation,
				$uri
			)
		"/>
		<twitter:tweet>
			<p:with-option name="status" select="$status"/>
			<p:with-option name="media-ids" select="$media-id"/>
		</twitter:tweet>
	</p:group>
	
	<p:declare-step type="twitter:upload-media">
		<p:input port="parameters" kind="parameter"/>
		<p:input port="source"/>
		<p:output port="result"/>
		<p:add-attribute match="/*" attribute-name="disposition">
			<p:with-option name="attribute-value" select="
				concat(
					'form-data; name=',
					codepoints-to-string(34),
					'media_data',
					codepoints-to-string(34)
				)
			"/>
		</p:add-attribute>
		<p:add-attribute match="/*" attribute-name="content-type" attribute-value="application/octet-stream"/>
		<p:wrap match="/*" wrapper="c:multipart"/>
		<p:add-attribute match="/*" attribute-name="content-type" attribute-value="multipart/form-data"/>
		<p:add-attribute match="/*" attribute-name="boundary" attribute-value="___"/>
		<p:wrap match="/*" wrapper="c:request"/>
		<p:add-attribute match="/*" attribute-name="override-content-type" attribute-value="text/json"/>
		<p:add-attribute match="/*" attribute-name="method" attribute-value="POST"/>
		<p:add-attribute match="/*" attribute-name="href" attribute-value="https://upload.twitter.com/1.1/media/upload.json"/>
		<twitter:sign-request/>
		<p:http-request/>
	</p:declare-step>
	

	<p:declare-step type="paperspast:get-image">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="href" required="true"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:request method="GET"/>
				</p:inline>
			</p:input>
		</p:identity>
		<p:add-attribute match="/c:request" attribute-name="href">
			<p:with-option name="attribute-value" select="$href"/>
		</p:add-attribute>
		<p:http-request/>
	</p:declare-step>

	
	
	<p:declare-step type="paperspast:on-this-day">
		<p:option name="text" select=" '' "/>
		<p:option name="years-ago" select=" '100' "/>
		<p:option name="content-type" select=" '' "/><!-- "" (all) | "ARTICLE" | "ADVERTISEMENT" | "ILLUSTRATION" -->
		<p:option name="match" select=" '1' " /><!-- 2='exact phrase' | 1='any' | 0='all' -->
		<p:output port="result"/>
		<p:variable name="date" select="
			substring(
				string(
					current-date() - xs:yearMonthDuration(
						concat('P', $years-ago, 'Y')
					)
				),
				1, 10
			)
		"/>
		<p:variable name="search-uri" select="
			concat(
				'http://paperspast.natlib.govt.nz/cgi-bin/paperspast?e=',
				'&amp;a=q',
				'&amp;hs=1',
				'&amp;r=1',
				'&amp;results=1',
				'&amp;t=', $match,
				'&amp;txq=', $text,
				'&amp;x=0',
				'&amp;y=0',
				'&amp;pbq=',
				'&amp;dafdq=', substring($date, 9, 2),
				'&amp;dafmq=', substring($date, 6, 2),
				'&amp;dafyq=', substring($date, 1, 4),
				'&amp;datdq=', substring($date, 9, 2),
				'&amp;datmq=', substring($date, 6, 2),
				'&amp;datyq=',  substring($date, 1, 4),
				'&amp;tyq=', fn:upper-case($content-type),
				'&amp;o=10',
				'&amp;sf=',
				'&amp;ssnip='
			)
		"/>
		<!-- execute search -->
		<paperspast:load-as-xml>
			<p:with-option name="href" select="$search-uri"/>
		</paperspast:load-as-xml>
		<!-- pick the first search result and request that page -->
		<paperspast:load-as-xml>
			<p:with-option name="href" select="
				concat(
					'http://paperspast.natlib.govt.nz',
					(//html:div[@class='search-results']/html:p/html:a[not(string(.)='Untitled')])[1]/@href
				)
			"/>
		</paperspast:load-as-xml>
		<p:make-absolute-uris match="@src | @href"/>
	</p:declare-step>
	
			<!-- code to trim all except "a" and "d" URI parameters from a paperspast article page, which we should because
			we might want to tweet this URL--><!--

		<p:group>
			<p:variable name="result-page-uri"
				select="(//html:div[@class='search-results']/html:p/html:a[not(string(.)='Untitled')])[1]/@href"/>
			<p:www-form-urldecode>
				<p:with-option name="value" select="substring-after($result-page-uri, '?')"/>
			</p:www-form-urldecode>

			<p:group>
				<p:variable name="short-page-uri" select="
					concat(
						'http://paperspast.natlib.govt.nz',
						substring-before($result-page-uri, '?'),
						'?a=', encode-for-uri(/c:param-set/c:param[@name='a']/@value),
						'&amp;d=', encode-for-uri(/c:param-set/c:param[@name='d']/@value)
					)
				"/>
			</p:group>
		</p:group>
-->
	
	<p:declare-step type="paperspast:load-as-xml">
		<!-- used to parse XHTML served as "text/html" -->
		<p:option name="href" required="true"/>
		<p:output port="result"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:request method="GET" override-content-type="application/xml"/>
				</p:inline>
			</p:input>
		</p:identity>
		<p:add-attribute match="/c:request" attribute-name="href">
			<p:with-option name="attribute-value" select="$href"/>
		</p:add-attribute>
		<p:http-request/>
		<p:add-xml-base/>
	</p:declare-step>
	
	

	<p:declare-step type="twitter:followers">
		<p:input port="parameters" kind="parameter"/>
		<p:output port="result"/>
		<p:identity name="list-followers">
			<p:input port="source">
				<p:inline>
					<c:request 
						method="GET" 
						href="https://api.twitter.com/1.1/followers/list.json">
					</c:request>
				</p:inline>
			</p:input>
		</p:identity>	
		<twitter:sign-request/>
		<p:http-request/>
	</p:declare-step>
	
	<p:declare-step type="twitter:tweet">
		<p:input port="parameters" kind="parameter"/>
		<p:output port="result"/>
		<p:option name="status" required="true"/>
		<p:option name="media-ids"/>
		<p:in-scope-names name="parameters"/>
		<p:xslt name="status-update-request">
			<p:input port="source">
				<p:inline>
					<c:request 
						override-content-type="text/json"
						method="POST" 
						href="https://api.twitter.com/1.1/statuses/update.json"/>
				</p:inline>
			</p:input>
			<p:input port="parameters">
				<p:pipe step="parameters" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:c="http://www.w3.org/ns/xproc-step">
						<xsl:param name="status"/>
						<xsl:param name="media-ids"/>
						<xsl:template match="c:request">
							<xsl:copy>
								<xsl:copy-of select="@*"/>
								<c:body content-type="application/x-www-form-urlencoded">
									<xsl:value-of select="
										concat(
											'status=', 
											encode-for-uri($status)
									)"/>
									<xsl:if test="$media-ids">
										<xsl:value-of select="
											concat(
												'&amp;media_ids=',
												encode-for-uri($media-ids)
											)
										"/>
									</xsl:if>
								</c:body>
							</xsl:copy>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<twitter:sign-request/>
		<p:http-request/>
		<!---->
	</p:declare-step>
	
	<p:declare-step type="twitter:www-form-urldecode">
		<!-- does not choke on an empty value -->
		<p:output port="result"/>
		<p:option name="value" required="true"/>
		<p:choose>
			<p:when test="string-length($value)=0">
				<p:identity>
					<p:input port="source">
						<p:inline><c:param-set/></p:inline>
					</p:input>
				</p:identity>
			</p:when>
			<p:otherwise>
				<p:www-form-urldecode>
					<p:with-option name="value" select="$value"/>
				</p:www-form-urldecode>
			</p:otherwise>
		</p:choose>
	</p:declare-step>

	<p:declare-step type="twitter:sign-request" name="sign-request">
		<!-- a c:request document -->
		<p:input port="source"/>
		<p:output port="result"/>
		<p:input port="parameters" kind="parameter"/>
		<p:parameters name="credentials">
			<p:input port="parameters">
				<p:pipe port="parameters" step="sign-request"/>
			</p:input>
		</p:parameters>
		<p:group>
			<p:variable name="consumer-key" select="/c:param-set/c:param[@name='consumer-key']/@value">
				<p:pipe step="credentials" port="result"/>
			</p:variable>
			<p:variable name="consumer-secret" select="/c:param-set/c:param[@name='consumer-secret']/@value">
				<p:pipe step="credentials" port="result"/>
			</p:variable>
			<p:variable name="access-token" select="/c:param-set/c:param[@name='access-token']/@value">
				<p:pipe step="credentials" port="result"/>
			</p:variable>
			<p:variable name="access-token-secret" select="/c:param-set/c:param[@name='access-token-secret']/@value">
				<p:pipe step="credentials" port="result"/>
			</p:variable>
			
			<!-- Generate OAuth parameter set -->
			<p:variable name="oauth_signature_method" select=" 'HMAC-SHA1' "/>
			<p:variable name="duration-since-unix-epoch" select="
				fn:current-dateTime() - xs:dateTime('1970-01-01T00:00:00Z')
			"/>
			<p:variable name="oauth_consumer_key" select="$consumer-key"/>
			<p:variable name="oauth_nonce" select="p:system-property('p:episode')"/>
			<p:variable name="oauth_timestamp" select="
				string(
					xs:integer(fn:seconds-from-duration($duration-since-unix-epoch)) +
					fn:minutes-from-duration($duration-since-unix-epoch) * 60 +
					fn:hours-from-duration($duration-since-unix-epoch) * 60 * 60 + fn:days-from-duration($duration-since-unix-epoch) * 24 * 60 * 60
				)
			"/>
			<p:variable name="oauth_token" select="$access-token"/>
			<p:variable name="oauth_version" select=" '1.0' "/>
			<p:variable name="url-parameter-string" select="substring-after(/c:request/@href, '?')">
				<p:pipe step="sign-request" port="source"/>
			</p:variable>
			<p:variable name="post-parameter-string" select="/c:request/c:body[@content-type='application/x-www-form-urlencoded']">
				<p:pipe step="sign-request" port="source"/>
			</p:variable>
			<!-- read variables into a param-set -->
			<p:in-scope-names name="oauth-and-other-variables"/>
			<!-- throw out all but the oauth_* parameters -->
			<p:delete name="oauth-parameters"
				match="/c:param-set/c:param[not(starts-with(@name, 'oauth_'))]">
				<p:input port="source">
					<p:pipe step="oauth-and-other-variables" port="result"/>
				</p:input>
			</p:delete>
			<!-- Read the URL parameters into a parameter set -->
			<twitter:www-form-urldecode name="url-parameters">
				<p:with-option name="value" select="$url-parameter-string"/>
			</twitter:www-form-urldecode>
			<!-- Read the POST parameters into a parameter set -->
			<twitter:www-form-urldecode name="post-parameters">
				<p:with-option name="value" select="$post-parameter-string"/>	
			</twitter:www-form-urldecode>
			<!-- merge the OAuth, POST, and URL parameters into a single set -->
			<p:wrap-sequence wrapper="c:param-set">
				<p:input port="source" select="/c:param-set/c:param">
					<p:pipe step="url-parameters" port="result"/>
					<p:pipe step="post-parameters" port="result"/>
					<p:pipe step="oauth-parameters" port="result"/>
				</p:input>
			</p:wrap-sequence>
			<!-- URI encode the parameters' keys and values -->
			<p:string-replace match="@name | @value" replace="encode-for-uri(.)"/>
			<!-- sort the parameters -->
			<p:xslt name="sorted-parameters">
				<p:input port="parameters">
					<p:empty/>
				</p:input>
				<p:input port="stylesheet">
					<p:inline>
						<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
							xmlns:c="http://www.w3.org/ns/xproc-step">
							<xsl:template match="/c:param-set">
								<xsl:copy>
									<xsl:for-each select="c:param">
										<xsl:sort select="@name"/>
										<xsl:sort select="@value"/>
										<xsl:copy-of select="."/>
									</xsl:for-each>
								</xsl:copy>
							</xsl:template>
						</xsl:stylesheet>
					</p:inline>
				</p:input>
			</p:xslt>
			<p:group>
				<!-- encode parameters into a parameter string -->
				<p:variable name="parameter-string" select="
					string-join(
						for $param in /c:param-set/c:param return concat($param/@name, '=', $param/@value),
						'&amp;'
					)
				"/>
				<!-- encode the request method, base URI, and parameter string into a "signature base string" to be signed -->
				<p:variable name="signature-base-string" select="
					concat(
						/c:request/@method,
						'&amp;',
						encode-for-uri(
							substring-before(
								concat(/c:request/@href, '?'),
								'?'
							)
						),
						'&amp;',
						encode-for-uri($parameter-string)
					)
				">
					<p:pipe step="sign-request" port="source"/>
				</p:variable>
				<!-- assemble the signing key -->
				<p:variable name="signing-key" select="concat(
					encode-for-uri($consumer-secret), 
					'&amp;', 
					encode-for-uri($access-token-secret)
				)"/>
				<!-- create a document to store the signature -->
				<p:identity>
					<p:input port="source">
						<p:inline>
							<signature value=""/>
						</p:inline>
					</p:input>
				</p:identity>
				<!-- hash the signature base string with the signing key, storing the resulting signature -->
				<p:hash name="signature" match="/signature/@value" algorithm="cx:hmac">
					<p:with-param name="cx:accessKey" select="$signing-key"/>
					<p:with-option name="value" select="$signature-base-string"/>
				</p:hash>
				<p:group>
					<p:variable name="oauth_signature" select="/signature/@value"/>
					<p:in-scope-names name="all-variables"/>
					<!-- URI encode all the values of the OAuth parameters -->
					<p:string-replace name="oauth-header-components" match="@value" replace="encode-for-uri(.)">
						<p:input port="source">
							<p:pipe step="all-variables" port="result"/>
						</p:input>
					</p:string-replace>
					<!-- Format the OAuth parameters into an Authorization request header -->
					<p:template name="authorization-header">
						<p:input port="parameters">
							<p:pipe step="oauth-header-components" port="result"/>
						</p:input>
						<p:input port="template">
							<p:inline>
								<c:header name="Authorization"
									value='OAuth oauth_consumer_key="{$oauth_consumer_key}", oauth_nonce="{$oauth_nonce}", oauth_signature="{$oauth_signature}", oauth_signature_method="{$oauth_signature_method}", oauth_timestamp="{$oauth_timestamp}", oauth_token="{$oauth_token}", oauth_version="{$oauth_version}"'
								/>
							</p:inline>
						</p:input>
					</p:template>
					<!-- insert the Authorization header into the HTTP request -->
					<p:insert position="first-child">
						<p:input port="source">
							<p:pipe step="sign-request" port="source"/>
						</p:input>
						<p:input port="insertion">
							<p:pipe step="authorization-header" port="result"/>
						</p:input>
					</p:insert>
				</p:group>
			</p:group>
		</p:group>
	</p:declare-step>
	
</p:declare-step>
