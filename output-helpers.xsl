<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsd="http://www.w3.org/2001/XMLSchema"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="output-numeric-conversion">
	<xsl:param name="type"/>
	<xsl:param name="go-string"/>
	<xsl:param name="go-val"/>
	<xsl:param name="indent"/>
	<xsl:param name="min-value"/>
	<xsl:param name="max-value"/>
	<xsl:param name="is-optional" select="''"/>

	<xsl:value-of select="concat($indent, '// Convert and validate ', $go-val, ' ', $type, ':', $NL)"/>
	<xsl:choose>
		<xsl:when test="is-optional = 'YES'">
			<xsl:value-of select="concat($indent, 'if len(', $go-string, ') &gt; 0 {', $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($indent, '{', $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:value-of select="concat($indent, $T, 'var n int', $NL)"/>
	<xsl:value-of select="concat($indent, $T, 'n, err = fmt.Sscanf(', $go-string, ', &quot;%v&quot;, &amp;', $go-val, ')', $NL)"/>
	<xsl:value-of select="concat($indent, $T, 'if n != 1 || err != nil {', $NL)"/>
	<xsl:value-of select="concat($indent, $T, $T, 'err = fmt.Errorf(&quot;Invalid integer data in attribute ', @name, '.\n&quot;)', $NL)"/>
	<xsl:value-of select="concat($indent, $T, $T, 'return', $NL)"/>
	<xsl:value-of select="concat($indent, $T, '}', $NL)"/>
	<!-- TODO: for float numbers evaluate regexp: -->
	<xsl:value-of select="concat($indent, $T, 'if ', $go-string, ' != fmt.Sprintf(&quot;%v&quot;,', $go-val, ') {', $NL)"/>
	<xsl:value-of select="concat($indent, $T, $T, 'err = fmt.Errorf(&quot;Junk integer data in attribute ', @name, '.\n&quot;)', $NL)"/>
	<xsl:value-of select="concat($indent, $T, $T, 'return', $NL)"/>
	<xsl:value-of select="concat($indent, $T, '}', $NL)"/>
	<xsl:variable name="is-float-type">
		<xsl:call-template name="is-float-type">
			<xsl:with-param name="type" select="$type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:if test="not($is-float-type = 'YES')">
		<xsl:value-of select="concat($indent, $T, 'if ', $go-val, ' &lt; ', $min-value, ' || ', $go-val, ' &gt; ', $max-value, ' {', $NL)"/>
		<xsl:value-of select="concat($indent, $T, $T, 'err = fmt.Errorf(&quot;Integer data out of range ', @name, '.\n&quot;)', $NL)"/>
		<xsl:value-of select="concat($indent, $T, $T, 'return', $NL)"/>
		<xsl:value-of select="concat($indent, $T, '}', $NL)"/>
	</xsl:if>
	<xsl:value-of select="concat($indent, '}', $NL)"/>
</xsl:template>

<xsl:template name="output-cardinality-check">
	<xsl:param name="xml-type"/>
	<xsl:param name="is-numeric-type"/>
	<xsl:param name="max-occurs"/>
	<xsl:param name="min-occurs"/>
	<xsl:param name="go-elem"/>
	<xsl:param name="indent"/>
	<xsl:choose>
		<xsl:when test="not($is-numeric-type = 'YES') and (not($max-occurs) or ($max-occurs = '1'))">
			<xsl:value-of select="concat($indent, 'if len(', $go-elem, ') &gt; ', 1, ' {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too many elements of type ', $xml-type, '\n&quot;)', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
		<xsl:when test="not($is-numeric-type = 'YES') and not($max-occurs = 'unbounded')">
			<xsl:value-of select="concat($indent, 'if len(', $go-elem, ') &gt; ', $max-occurs, ' {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too many elements of type ', $xml-type, '\n&quot;)', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
		<xsl:when test="not($max-occurs) or ($max-occurs = '1')">
			<xsl:value-of select="concat($indent, 'if len(', $go-elem, 'StringRep) &gt; ', 1, ' {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too many elements of type ', $xml-type, '\n&quot;)', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
		<xsl:when test="not($max-occurs = 'unbounded')">
			<xsl:value-of select="concat($indent, 'if len(', $go-elem, 'StringRep) &gt; ', $max-occurs, ' {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too many elements of type ', $xml-type, '\n&quot;)', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
	</xsl:choose>
	<xsl:choose>
		<xsl:when test="not($is-numeric-type = 'YES') and (not($min-occurs) or ($min-occurs = 1))">
			<xsl:value-of select="concat($indent, 'if len(', $go-elem, ') &lt; ', 1, ' {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too few elements of type ', $xml-type, '\n&quot;)', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
		<xsl:when test="not($is-numeric-type = 'YES') and not($min-occurs = 0)">
			<xsl:value-of select="concat($indent, 'if len(', $go-elem, ') &lt; ', $min-occurs, ' {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too few elements of type ', $xml-type, '\n&quot;)', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
		<xsl:when test="not($min-occurs) or ($min-occurs = 1)">
			<xsl:value-of select="concat($indent, 'if len(', $go-elem, 'StringRep) &lt; ', 1, ' {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too few elements of type ', $xml-type, '\n&quot;)', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
		<xsl:when test="not($min-occurs = 0)">
			<xsl:value-of select="concat($indent, 'if len(', $go-elem, 'StringRep) &lt; ', $min-occurs, ' {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too few elements of type ', $xml-type, '\n&quot;)', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>

