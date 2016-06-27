<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsd="http://www.w3.org/2001/XMLSchema"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="output-helpers.xsl"/>

<xsl:template match="xsd:attribute[@ref]">
	<xsl:param name="go-elem"/>
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:param name="mode"/>
	<!-- TODO: Resolve ref -->
	<xsl:choose>
		<xsl:when test="$mode = 'definition'">
			<xsl:choose>
				<xsl:when test="@ref = 'xml:space'">
					<xsl:value-of select="concat($indent, 'Space string `xml:&quot;space,attr&quot;`', $NL)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($indent, 'TODO: referenced attribute ', @ref, $NL)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:when test="($mode = 'validation') and not($suppress-validation = 'true')">
			<!-- TODO -->
		</xsl:when>
	</xsl:choose>
</xsl:template>

<xsl:template name="output-integer-attribute">
	<!-- active element: xsd:attribute -->
	<xsl:param name="go-attr"/>
	<xsl:param name="indent"/>
	<xsl:param name="min-value"/>
	<xsl:param name="max-value"/>
	<xsl:variable name="go-attr-string" select="concat($go-attr, 'StringRep')"/>
	<xsl:variable name="is-optional">
		<xsl:if test="not(@use = 'required')">
			<xsl:value-of select="'YES'"/>
		</xsl:if>
	</xsl:variable>
	<xsl:call-template name="output-numeric-conversion">
		<xsl:with-param name="type"        select="@type"/>
		<xsl:with-param name="go-string"   select="$go-attr-string"/>
		<xsl:with-param name="go-val"      select="$go-attr"/>
		<xsl:with-param name="indent"      select="$indent"/>
		<xsl:with-param name="min-value"   select="$min-value"/>
		<xsl:with-param name="max-value"   select="$max-value"/>
		<xsl:with-param name="is-optional" select="$is-optional"/>
	</xsl:call-template>
</xsl:template>

<xsl:template name="handle-integer-attribute">
	<!-- active element: xsd:attribute -->
	<xsl:param name="go-attr"/>
	<xsl:param name="indent"/>
	<xsl:variable name="min-value">
		<xsl:call-template name="get-min-value">
			<xsl:with-param name="type" select="@type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="max-value">
		<xsl:call-template name="get-max-value">
			<xsl:with-param name="type" select="@type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:call-template name="output-integer-attribute">
		<xsl:with-param name="go-attr" select="$go-attr"/>
		<xsl:with-param name="indent" select="$indent"/>
		<xsl:with-param name="min-value">
			<xsl:value-of select="$min-value"/>
		</xsl:with-param >
		<xsl:with-param name="max-value">
			<xsl:value-of select="$max-value"/>
		</xsl:with-param >
	</xsl:call-template>
</xsl:template>

<xsl:template match="xsd:attribute[not(@ref)]">
	<xsl:param name="go-elem"/>
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:param name="mode"/>
	<xsl:variable name="attr-name">
		<xsl:call-template name="make-go-name">
			<xsl:with-param name="name" select="@name"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="attr-type">
		<xsl:call-template name="go-type">
			<xsl:with-param name="type" select="@type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$mode = 'definition'">
			<xsl:choose>
				<xsl:when test="$attr-type = 'string'">
					<xsl:value-of select="concat($indent, $attr-name, ' ', $attr-type, ' `xml:&quot;', @name, ',attr&quot;`', $NL)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($indent, $attr-name, 'StringRep string `xml:&quot;', @name, ',attr&quot;`', $NL)"/>
					<xsl:value-of select="concat($indent, $attr-name, ' ', $attr-type, ' `xml:&quot;-&quot;`', $NL)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:when test="($mode = 'validation') and not($suppress-validation = 'true')">
			<xsl:variable name="go-attr"        select="concat($go-elem, '.', $attr-name)"/>
			<xsl:variable name="go-attr-string" select="concat($go-attr, 'StringRep')"/>
			<xsl:variable name="type" select="@type"/>
			<xsl:variable name="simpletype"     select="/xsd:schema/xsd:simpleType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
			<xsl:variable name="is-integer-type">
				<xsl:call-template name="is-integer-type">
					<xsl:with-param name="type" select="@type"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="is-integer-simpletype">
				<xsl:call-template name="is-integer-simpletype">
					<xsl:with-param name="type" select="@type"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="is-fractional-type">
				<xsl:if test="(@type = 'xsd:decimal') or
				              (@type = 'xsd:double')">
					<xsl:value-of select="'YES'"/>
				</xsl:if>
			</xsl:variable>
			<xsl:if test="@use = 'required'">
				<xsl:choose>
					<xsl:when test="$attr-type = 'string'">
						<xsl:value-of select="concat($indent, 'if len(', $go-attr, ') == 0 {', $NL)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat($indent, 'if len(', $go-attr-string, ') == 0 {', $NL)"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Missing attribute ', @name, '\n&quot;)', $NL)"/>
				<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
				<xsl:value-of select="concat($indent, '}', $NL)"/>
			</xsl:if>
			<xsl:if test="@default">
				<xsl:choose>
					<xsl:when test="$attr-type = 'string'">
						<xsl:value-of select="concat($indent, 'if len(', $go-attr, ') == 0 {', $NL)"/>
						<xsl:value-of select="concat($indent, $T, $go-attr, ' = &quot;', @default, '&quot;', $NL)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat($indent, 'if len(', $go-attr-string, ') == 0 {', $NL)"/>
						<xsl:value-of select="concat($indent, $T, $go-attr-string, ' = &quot;', @default, '&quot;', $NL)"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="concat($indent, '}', $NL)"/>
			</xsl:if>
			<xsl:if test="@fixed">
				<xsl:choose>
					<xsl:when test="$attr-type = 'string'">
						<xsl:value-of select="concat($indent, $T, $go-attr, ' = &quot;', @fixed, '&quot;', $NL)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat($indent, $T, $go-attr-string, ' = &quot;', @fixed, '&quot;', $NL)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@type = 'xsd:string'">
					<xsl:value-of select="concat($indent, '// Nothing to validate', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="$is-integer-type = 'YES'">
					<xsl:call-template name="handle-integer-attribute">
						<!-- active element: xsd:attribute -->
						<xsl:with-param name="go-attr" select="$go-attr"/>
						<xsl:with-param name="indent" select="$indent"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$is-integer-simpletype = 'YES'">
					<xsl:value-of select="concat($indent, '// Validate simple type attribute', $NL)"/>
					<xsl:call-template name="handle-integer-attribute">
						<!-- active element: xsd:attribute -->
						<xsl:with-param name="go-attr" select="$go-attr"/>
						<xsl:with-param name="indent" select="$indent"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$is-fractional-type = 'YES'">
					<xsl:value-of select="concat($indent, '// TODO: validate fractional types', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="@type = 'xsd:dateTime'">
					<xsl:value-of select="concat($indent, '// TODO: validate xsd:dateTime', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="$simpletype/xsd:restriction/xsd:enumeration">
					<xsl:variable name="go-type">
						<xsl:call-template name="make-go-name">
							<xsl:with-param name="name" select="$simpletype/@name"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:value-of select="concat($indent, 'err = ValidateXml', $go-type, '(', $go-elem, '.', $attr-name, ')', $NL)"/>
					<xsl:value-of select="concat($indent, 'if err != nil {', $NL)"/>
					<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
					<xsl:value-of select="concat($indent, '}', $NL)"/>
				</xsl:when>
				<xsl:when test="$simpletype/xsd:restriction/xsd:pattern">
					<xsl:value-of select="concat($indent, '// TODO: validate pattern', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="@type = 'xsd:NMTOKEN'">
					<xsl:value-of select="concat($indent, '// TODO: validate xsd:NMTOKEN', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($indent, '// other attribute ', $attr-name, $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
