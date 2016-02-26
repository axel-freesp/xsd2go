<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsd="http://www.w3.org/2001/XMLSchema"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:param name="package-name" select="'main'"/>

<xsl:include href="xsd2go-helpers.xsl"/>

<xsl:template match="xsd:schema">
	<xsl:value-of select="concat('package ', translate($package-name, '-', '_'), $NL, $NL)"/>
	<xsl:value-of select="concat('import (', $NL)"/>
	<xsl:value-of select="concat($T, '&quot;encoding/xml&quot;', $NL)"/>
	<xsl:value-of select="concat($T, '&quot;fmt&quot;', $NL)"/>
	<xsl:value-of select="concat($T, '&quot;io/ioutil&quot;', $NL)"/>
	<xsl:value-of select="concat(')', $NL, $NL)"/>
	<xsl:if test="@targetNamespace">
		<xsl:value-of select="concat('const namespace = &quot;', @targetNamespace, '&quot;', $NL)"/>
	</xsl:if>
	<xsl:value-of select="concat('const xmlHeader = `&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;', $NL, '`', $NL)"/>
	<xsl:apply-templates select="xsd:complexType"/>
	<xsl:apply-templates select="xsd:simpleType" mode="validation"/>
	<xsl:apply-templates select="xsd:element" mode="toplevel"/>
</xsl:template>

<!-- complexType -->

<xsl:template match="xsd:complexType">
	<xsl:variable name="tname" select="@name"/>
	<xsl:value-of select="concat('// complexType ', $tname, $NL)"/>
	<xsl:message>
	complexType '<xsl:value-of select="$tname"/>'
	</xsl:message>
	<xsl:variable name="go-name">
		<xsl:call-template name="make-go-name">
			<xsl:with-param name="name" select="$tname"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:apply-templates select="." mode="definition">
		<xsl:with-param name="tname"   select="$tname"/>
		<xsl:with-param name="go-name" select="$go-name"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="." mode="validation">
		<xsl:with-param name="tname"   select="$tname"/>
		<xsl:with-param name="go-name" select="$go-name"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:complexType" mode="definition">
	<xsl:param name="tname"/>
	<xsl:param name="go-name"/>
	<xsl:value-of select="concat('type Xml', $go-name, ' struct {', $NL)"/>
	<xsl:variable name="global-element" select="/xsd:schema/xsd:element[(@type = $tname) or (substring-after(@type, ':') = $tname)]"/>
	<xsl:if test="$global-element">
		<xsl:choose>
			<xsl:when test="/xsd:schema/@targetNamespace">
				<xsl:value-of select="concat($T, 'XMLName xml.Name `xml:&quot;', /xsd:schema/@targetNamespace, ' ', $global-element/@name, '&quot;`', $NL)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($T, 'XMLName xml.Name', $NL)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:if>
	<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup" mode="definition">
		<xsl:with-param name="xmlpath" select="''"/>
		<xsl:with-param name="indent" select="$T"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="xsd:sequence|xsd:simpleContent" mode="definition">
		<xsl:with-param name="xmlpath" select="''"/>
		<xsl:with-param name="indent" select="$T"/>
	</xsl:apply-templates>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
</xsl:template>

<xsl:template match="xsd:complexType" mode="validation">
	<xsl:param name="tname"/>
	<xsl:param name="go-name"/>
	<xsl:value-of select="concat('func (g *Xml', $go-name, ') Validate() (err error) {', $NL)"/>
	<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup" mode="validation">
		<xsl:with-param name="go-elem" select="'g'"/>
		<xsl:with-param name="indent" select="$T"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="xsd:sequence|xsd:simpleContent" mode="validation">
		<xsl:with-param name="go-elem" select="'g'"/>
		<xsl:with-param name="indent" select="$T"/>
	</xsl:apply-templates>
	<xsl:value-of select="concat($T, 'return', $NL)"/>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
</xsl:template>

<!-- attribute, attributeGroup -->

<xsl:template match="xsd:attributeGroup" mode="definition">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:variable name="ref">
		<xsl:choose>
			<xsl:when test="contains(@ref, ':')">
				<xsl:value-of select="substring-after(@ref, ':')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@ref"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="group" select="/xsd:schema/xsd:attributeGroup[@name = $ref]"/>
	<xsl:apply-templates select="$group/xsd:attribute|$group/xsd:attributeGroup" mode="definition">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:attribute[@ref]" mode="definition">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<!-- TODO: Resolve ref -->
	<xsl:choose>
		<xsl:when test="@ref = 'xml:space'">
			<xsl:value-of select="concat($indent, 'Space string `xml:&quot;space,attr&quot;`', $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($indent, 'TODO: referenced attribute ', @ref, $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="xsd:attribute[not(@ref)]" mode="definition">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
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
	<xsl:value-of select="concat($indent, $attr-name, ' ', $attr-type, ' `xml:&quot;', @name, ',attr&quot;`', $NL)"/>
</xsl:template>


<xsl:template match="xsd:attributeGroup" mode="validation">
	<xsl:param name="go-elem"/>
	<xsl:param name="indent"/>
	<xsl:variable name="ref">
		<xsl:choose>
			<xsl:when test="contains(@ref, ':')">
				<xsl:value-of select="substring-after(@ref, ':')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@ref"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="group" select="/xsd:schema/xsd:attributeGroup[@name = $ref]"/>
	<xsl:apply-templates select="$group/xsd:attribute|$group/xsd:attributeGroup" mode="validation">
		<xsl:with-param name="go-elem" select="$go-elem"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:attribute" mode="validation">
	<xsl:param name="go-elem"/>
	<xsl:param name="indent"/>
	<xsl:variable name="go-name">
		<xsl:call-template name="make-go-name">
			<xsl:with-param name="name" select="@name"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="type" select="@type"/>
	<xsl:variable name="simpletype" select="/xsd:schema/xsd:simpleType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
	<xsl:choose>
		<xsl:when test="$type = 'xsd:string'">
			<xsl:value-of select="concat($indent, '// Nothing to validate', $NL)"/>
			<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:dateTime'">
			<xsl:value-of select="concat($indent, '// TODO: validate xsd:dateTime', $NL)"/>
			<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
		</xsl:when>
		<xsl:when test="$simpletype/xsd:restriction/xsd:enumeration">
			<xsl:variable name="go-type">
				<xsl:call-template name="make-go-name">
					<xsl:with-param name="name" select="$simpletype/@name"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:value-of select="concat($indent, 'err = ValidateXml', $go-type, '(', $go-elem, '.', $go-name, ')', $NL)"/>
			<xsl:value-of select="concat($indent, 'if err != nil {', $NL)"/>
			<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:when>
		<xsl:when test="$simpletype/xsd:restriction/xsd:pattern">
			<xsl:value-of select="concat($indent, '// TODO: validate pattern', $NL)"/>
			<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:NMTOKEN'">
			<xsl:value-of select="concat($indent, '// TODO: validate xsd:NMTOKEN', $NL)"/>
			<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($indent, '// other attribute ', $go-name, $NL)"/>
			<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- simpleType -->

<xsl:template match="xsd:simpleType" mode="validation">
	<xsl:variable name="go-type">
		<xsl:call-template name="make-go-name">
			<xsl:with-param name="name" select="@name"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="xsd:restriction/xsd:enumeration">
			<xsl:value-of select="concat('func ValidateXml', $go-type, '(val string) (err error) {', $NL)"/>
			<xsl:value-of select="concat($T, 'enums := []string{', $NL)"/>
			<xsl:for-each select="xsd:restriction/xsd:enumeration">
				<xsl:value-of select="concat($T, $T, '&quot;', @value, '&quot;,', $NL)"/>
			</xsl:for-each>
			<xsl:value-of select="concat($T, '}', $NL)"/>
			<xsl:value-of select="concat($T, 'match := false', $NL)"/>
			<xsl:value-of select="concat($T, 'for _, v := range enums {', $NL)"/>
			<xsl:value-of select="concat($T, $T, 'if v == val {', $NL)"/>
			<xsl:value-of select="concat($T, $T, $T, 'match = true', $NL)"/>
			<xsl:value-of select="concat($T, $T, $T, 'break', $NL)"/>
			<xsl:value-of select="concat($T, $T, '}', $NL)"/>
			<xsl:value-of select="concat($T, '}', $NL)"/>
			<xsl:value-of select="concat($T, 'if !match {', $NL)"/>
			<xsl:value-of select="concat($T, $T, 'err = fmt.Errorf(&quot;Validation failed: %s is no valid enumeration value for XML type ', @name, '\n&quot;, val)', $NL)"/>
			<xsl:value-of select="concat($T, '}', $NL)"/>
			<xsl:value-of select="concat($T, 'return', $NL)"/>
			<xsl:value-of select="concat('}', $NL, $NL)"/>
		</xsl:when>
	</xsl:choose>
</xsl:template>

<!-- simpleContent -->

<xsl:template match="xsd:simpleContent" mode="definition">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:apply-templates select="xsd:extension" mode="definition">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:simpleContent" mode="validation">
	<xsl:param name="go-elem"/>
	<xsl:param name="indent"/>
	<xsl:value-of select="concat($T, '// simpleContent validation', $NL)"/>
	<xsl:apply-templates select="xsd:extension" mode="validation">
		<xsl:with-param name="go-elem" select="$go-elem"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:extension" mode="definition">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:variable name="basetype">
		<xsl:call-template name="go-type">
			<xsl:with-param name="type" select="@base"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$basetype = 'string'">
			<xsl:value-of select="concat($indent, 'CharData string `xml:&quot;', $xmlpath, ',chardata&quot;`', $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($indent, 'TypedData ', $basetype, $NL)"/>
			<xsl:value-of select="concat($indent, 'CharData []byte `xml:&quot;', $xmlpath, ',chardata&quot;`', $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup" mode="definition">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:extension" mode="validation">
	<xsl:param name="go-elem"/>
	<xsl:param name="indent"/>
	<xsl:variable name="basetype">
		<xsl:call-template name="go-type">
			<xsl:with-param name="type" select="@base"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$basetype = 'string'">
			<xsl:value-of select="concat($indent, '// Nothing to validate for ', $go-elem, '.CharData', $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($indent, '// TODO validate ', $go-elem, '.CharData and convert to TypedData ', $basetype, $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup" mode="validation">
		<xsl:with-param name="go-elem" select="$go-elem"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:sequence" mode="definition">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:apply-templates select="xsd:element|xsd:choice|xsd:group" mode="definition">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:sequence" mode="validation">
	<xsl:param name="go-elem"/>
	<xsl:param name="indent"/>
	<xsl:apply-templates select="xsd:element|xsd:choice|xsd:group" mode="validation">
		<xsl:with-param name="go-elem" select="$go-elem"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:element" mode="definition">
	<xsl:param name="parent-min-occurs" select="1"/>
	<xsl:param name="parent-max-occurs" select="1"/>
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:variable name="min-occurs">
		<xsl:choose>
			<xsl:when test="@minOccurs">
				<xsl:value-of select="@minOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$parent-min-occurs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="max-occurs">
		<xsl:choose>
			<xsl:when test="@maxOccurs">
				<xsl:value-of select="@maxOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$parent-max-occurs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="go-name">
		<xsl:call-template name="make-go-name">
			<xsl:with-param name="name" select="@name"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="xsd:complexType">
			<xsl:value-of select="concat($indent, '/* Inner complexType */', $NL)"/>
			<xsl:apply-templates select="xsd:complexType" mode="inner">
				<xsl:with-param name="xmlpath" select="concat($xmlpath, @name)"/>
				<xsl:with-param name="min-occurs" select="$min-occurs"/>
				<xsl:with-param name="max-occurs" select="$max-occurs"/>
				<xsl:with-param name="indent" select="$indent"/>
				<xsl:with-param name="name" select="$go-name"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="go-type">
				<xsl:call-template name="make-go-type">
					<xsl:with-param name="tname" select="@type"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="(($min-occurs = '1') or not($min-occurs)) and (($max-occurs = '1') or not($max-occurs))">
					<xsl:value-of select="concat($indent, $go-name, ' ', $go-type, ' `xml:&quot;', $xmlpath, @name, '&quot;`', $NL)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($indent, $go-name, ' []', $go-type, ' `xml:&quot;', $xmlpath, @name, '&quot;`', $NL)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="xsd:element" mode="validation">
	<xsl:param name="go-elem"/>
	<xsl:param name="parent-min-occurs" select="1"/>
	<xsl:param name="parent-max-occurs" select="1"/>
	<xsl:param name="indent"/>
	<xsl:variable name="min-occurs">
		<xsl:choose>
			<xsl:when test="@minOccurs">
				<xsl:value-of select="@minOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$parent-min-occurs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="max-occurs">
		<xsl:choose>
			<xsl:when test="@maxOccurs">
				<xsl:value-of select="@maxOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$parent-max-occurs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="go-name">
		<xsl:call-template name="make-go-name">
			<xsl:with-param name="name" select="@name"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="xsd:complexType">
			<xsl:value-of select="concat($indent, '/* Validate inner complexType */', $NL)"/>
			<xsl:apply-templates select="xsd:complexType" mode="validate-inner">
				<xsl:with-param name="min-occurs" select="$min-occurs"/>
				<xsl:with-param name="max-occurs" select="$max-occurs"/>
				<xsl:with-param name="go-elem" select="$go-elem"/>
				<xsl:with-param name="indent" select="$indent"/>
				<xsl:with-param name="name" select="$go-name"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="go-type">
				<xsl:call-template name="make-go-type">
					<xsl:with-param name="tname" select="@type"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$go-type = 'string'">
					<xsl:value-of select="concat($indent, '/* TODO: validation of ', @type, ' */', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="$go-type = 'float64'">
					<xsl:value-of select="concat($indent, '/* TODO: validation of ', @type, ' */', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="$go-type = 'int'">
					<xsl:value-of select="concat($indent, '/* TODO: validation of ', @type, ' */', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="$go-type = 'uint'">
					<xsl:value-of select="concat($indent, '/* TODO: validation of ', @type, ' */', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="$go-type = 'bool'">
					<xsl:value-of select="concat($indent, '/* TODO: validation of ', @type, ' */', $NL)"/>
					<xsl:value-of select="concat($indent, '_ = ', $go-elem, $NL)"/>
				</xsl:when>
				<xsl:when test="(($min-occurs = '1') or not($min-occurs)) and (($max-occurs = '1') or not($max-occurs))">
					<xsl:value-of select="concat($indent, '/* Validate element of type ', @type, ' */', $NL)"/>
					<xsl:value-of select="concat($indent, 'err = ', $go-elem, '.', $go-name, '.Validate()', $NL)"/>
					<xsl:value-of select="concat($indent, 'if err != nil {', $NL)"/>
					<xsl:value-of select="concat($indent, $T, 'return', $NL)"/>
					<xsl:value-of select="concat($indent, '}', $NL)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($indent, '/* Validate array of type ', @type, ' */', $NL)"/>
					<xsl:if test="not($max-occurs = 'unbounded')">
						<xsl:value-of select="concat($indent, 'if len(', $go-elem, '.', $go-name, ') &gt; ', $max-occurs, ' {', $NL)"/>
						<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too many elements of type ', @type, '\n&quot;)', $NL)"/>
						<xsl:value-of select="concat($indent, '}', $NL)"/>
					</xsl:if>
					<xsl:if test="not($min-occurs = 0)">
						<xsl:value-of select="concat($indent, 'if len(', $go-elem, '.', $go-name, ') &lt; ', $min-occurs, ' {', $NL)"/>
						<xsl:value-of select="concat($indent, $T, 'err = fmt.Errorf(&quot;Too few elements of type ', @type, '\n&quot;)', $NL)"/>
						<xsl:value-of select="concat($indent, '}', $NL)"/>
					</xsl:if>
					<xsl:value-of select="concat($indent, 'for _, elem := range ', $go-elem, '.', $go-name, ' {', $NL)"/>
					<xsl:value-of select="concat($indent, $T, 'err = elem.Validate()', $NL)"/>
					<xsl:value-of select="concat($indent, $T, 'if err != nil {', $NL)"/>
					<xsl:value-of select="concat($indent, $T, $T, 'return', $NL)"/>
					<xsl:value-of select="concat($indent, $T, '}', $NL)"/>
					<xsl:value-of select="concat($indent, '}', $NL)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="xsd:complexType" mode="inner">
	<xsl:param name="min-occurs" select="1"/>
	<xsl:param name="max-occurs" select="1"/>
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:param name="name"/>
	<xsl:choose>
		<xsl:when test="(($min-occurs = '1') or not($min-occurs)) and (($max-occurs = '1') or not($max-occurs))">
			<xsl:value-of select="concat($indent, $name, ' struct {', $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($indent, $name, ' []struct {', $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup" mode="definition">
		<xsl:with-param name="xmlpath" select="''"/>
		<xsl:with-param name="indent" select="concat($indent, $T)"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="xsd:sequence|xsd:choice|xsd:simpleContent" mode="definition">
		<xsl:with-param name="parent-min-occurs" select="$min-occurs"/>
		<xsl:with-param name="parent-max-occurs" select="$max-occurs"/>
		<xsl:with-param name="xmlpath" select="''"/>
		<xsl:with-param name="indent" select="concat($indent, $T)"/>
	</xsl:apply-templates>
	<xsl:value-of select="concat($indent, '} `xml:&quot;', $xmlpath, '&quot;`', $NL)"/>
</xsl:template>

<xsl:template match="xsd:complexType" mode="validate-inner">
	<xsl:param name="min-occurs" select="1"/>
	<xsl:param name="max-occurs" select="1"/>
	<xsl:param name="go-elem"/>
	<xsl:param name="indent"/>
	<xsl:param name="name"/>
	<xsl:choose>
		<xsl:when test="(($min-occurs = '1') or not($min-occurs)) and (($max-occurs = '1') or not($max-occurs))">
			<xsl:value-of select="concat($indent, '// ', $go-elem, '.', $name, ': single element', $NL)"/>
			<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup" mode="validation">
				<xsl:with-param name="go-elem" select="concat($go-elem, '.', $name)"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="xsd:sequence|xsd:choice|xsd:simpleContent" mode="validation">
				<xsl:with-param name="parent-min-occurs" select="$min-occurs"/>
				<xsl:with-param name="parent-max-occurs" select="$max-occurs"/>
				<xsl:with-param name="go-elem" select="concat($go-elem, '.', $name)"/>
				<xsl:with-param name="indent" select="concat($indent, $T)"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($indent, '// ', $go-elem, '.', $name, ': array', $NL)"/>
			<xsl:value-of select="concat($indent, 'for _, elem := range ', $go-elem, '.', $name, ' {', $NL)"/>
				<!--xsl:value-of select="concat($T, $T, '_ = elem', $NL)"/-->
				<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup" mode="validation">
					<xsl:with-param name="go-elem" select="'elem'"/>
					<xsl:with-param name="indent" select="concat($indent, $T)"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="xsd:sequence|xsd:choice|xsd:simpleContent" mode="validation">
					<xsl:with-param name="parent-min-occurs" select="$min-occurs"/>
					<xsl:with-param name="parent-max-occurs" select="$max-occurs"/>
					<xsl:with-param name="go-elem" select="'elem'"/>
					<xsl:with-param name="indent" select="concat($indent, $T)"/>
				</xsl:apply-templates>
			<xsl:value-of select="concat($indent, '}', $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="xsd:choice" mode="definition">
	<xsl:param name="parent-min-occurs" select="1"/>
	<xsl:param name="parent-max-occurs" select="1"/>
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:variable name="min-occurs">
		<xsl:choose>
			<xsl:when test="@minOccurs">
				<xsl:value-of select="@minOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$parent-min-occurs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="max-occurs">
		<xsl:choose>
			<xsl:when test="@maxOccurs">
				<xsl:value-of select="@maxOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$parent-max-occurs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:apply-templates select="xsd:element|xsd:choice|xsd:group" mode="definition">
		<xsl:with-param name="parent-min-occurs" select="$min-occurs"/>
		<xsl:with-param name="parent-max-occurs" select="$max-occurs"/>
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:choice" mode="validation">
	<xsl:param name="go-elem"/>
	<xsl:param name="parent-min-occurs" select="1"/>
	<xsl:param name="parent-max-occurs" select="1"/>
	<xsl:param name="indent"/>
	<xsl:variable name="min-occurs">
		<xsl:choose>
			<xsl:when test="@minOccurs">
				<xsl:value-of select="@minOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$parent-min-occurs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="max-occurs">
		<xsl:choose>
			<xsl:when test="@maxOccurs">
				<xsl:value-of select="@maxOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$parent-max-occurs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:apply-templates select="xsd:element|xsd:choice|xsd:group" mode="validation">
		<xsl:with-param name="parent-min-occurs" select="$min-occurs"/>
		<xsl:with-param name="parent-max-occurs" select="$max-occurs"/>
		<xsl:with-param name="go-elem" select="$go-elem"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:group" mode="definition">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:variable name="ref">
		<xsl:choose>
			<xsl:when test="contains(@ref, ':')">
				<xsl:value-of select="substring-after(@ref, ':')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@ref"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="group" select="/xsd:schema/xsd:group[@name = $ref]"/>
	<xsl:value-of select="concat($indent, '// Group ', $ref, $NL)"/>
	<xsl:apply-templates select="$group/xsd:sequence|$group/xsd:choice|$group/xsd:group" mode="definition">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:group" mode="validation">
	<xsl:param name="go-elem"/>
	<xsl:param name="indent"/>
	<xsl:variable name="ref">
		<xsl:choose>
			<xsl:when test="contains(@ref, ':')">
				<xsl:value-of select="substring-after(@ref, ':')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@ref"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="group" select="/xsd:schema/xsd:group[@name = $ref]"/>
	<xsl:value-of select="concat($T, '// Validate group ', $ref, $NL)"/>
	<xsl:apply-templates select="$group/xsd:sequence|$group/xsd:choice|$group/xsd:group" mode="validation">
		<xsl:with-param name="go-elem" select="$go-elem"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<!--##########################################################-->

<xsl:template match="xsd:element" mode="toplevel">
	<xsl:variable name="typename" select="@type"/>
	<xsl:value-of select="concat('// Toplevel element ', @name, ' of type ', @type, $NL)"/>
	<xsl:variable name="go-type">
		<xsl:call-template name="make-go-type">
			<xsl:with-param name="tname" select="@type"/>
		</xsl:call-template>
	</xsl:variable>
	<!--
	func XmlLibraryNew() *XmlLibrary {
		return &XmlLibrary{xml.Name{freespNamespace, "library"}, "1.0", nil, nil, nil}
	}
	-->
	<xsl:value-of select="concat('func ', $go-type, 'New() *', $go-type, ' {', $NL)"/>
	<xsl:choose>
		<xsl:when test="/xsd:schema/@targetNamespace">
			<xsl:value-of select="concat($T, 'return &amp;', $go-type, '{XMLName: xml.Name{namespace, &quot;', @name, '&quot;}}', $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($T, 'return &amp;', $go-type, '{}', $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
	<!--
	func (g *XmlLibrary) Read(data []byte) (cnt int, err error) {
		err = xml.Unmarshal(data, g)
		if err != nil {
			return
		}
		cnt = len(data)
		return
	}
	-->
	<xsl:value-of select="concat('func (g *', $go-type, ') Read(data []byte) (cnt int, err error) {', $NL)"/>
	<xsl:value-of select="concat($T, 'err = xml.Unmarshal(data, g)', $NL)"/>
	<xsl:value-of select="concat($T, 'if err != nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'return', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, 'cnt = len(data)', $NL)"/>
	<xsl:value-of select="concat($T, 'return', $NL)"/>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
	<!--
	func (g *XmlLibrary) Write() (data []byte, err error) {
		data, err = xml.MarshalIndent(g, "", "   ")
		if err != nil {
			err = fmt.Errorf("XmlLibrary.Write error: %v", err)
		}
		return
	}
	-->
	<xsl:value-of select="concat('func (g *', $go-type, ') Write() (data []byte, err error) {', $NL)"/>
	<xsl:value-of select="concat($T, 'data, err = xml.MarshalIndent(g, &quot;&quot;, &quot;', $T, '&quot;)', $NL)"/>
	<xsl:value-of select="concat($T, 'if err != nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'err = fmt.Errorf(&quot;', $go-type, '.Write error: %v&quot;, err)', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, 'return', $NL)"/>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
	<!--
	func (g *XmlLibrary) ReadFile(filepath string) error {
		data, err := ioutil.ReadFile(filepath)
		if err != nil {
			return fmt.Errorf("XmlLibrary.ReadFile error: Failed to read file %s", filepath)
		}
		_, err = g.Read(data)
		if err != nil {
			return fmt.Errorf("XmlLibrary.ReadFile error: %v", err)
		}
		return err
	}
	-->
	<xsl:value-of select="concat('func (g *', $go-type, ') ReadFile(filepath string) error {', $NL)"/>
	<xsl:value-of select="concat($T, 'data, err := ioutil.ReadFile(filepath)', $NL)"/>
	<xsl:value-of select="concat($T, 'if err != nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'return fmt.Errorf(&quot;', $go-type, '.ReadFile error: Failed to read file %s&quot;, filepath)', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, '_, err = g.Read(data)', $NL)"/>
	<xsl:value-of select="concat($T, 'if err != nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'return fmt.Errorf(&quot;', $go-type, '.ReadFile error: %v&quot;, err)', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, 'return err', $NL)"/>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
	<!--
	func (g *XmlLibrary) WriteFile(filepath string) error {
		data, err := g.Write()
		if err != nil {
			return err
		}
		buf := make([]byte, len(data)+len(xmlHeader))
		for i := 0; i < len(xmlHeader); i++ {
			buf[i] = xmlHeader[i]
		}
		for i := 0; i < len(data); i++ {
			buf[i+len(xmlHeader)] = data[i]
		}
		return tool.WriteFile(filepath, buf)
	}
	-->
	<xsl:value-of select="concat('func (g *', $go-type, ') WriteFile(filepath string) error {', $NL)"/>
	<xsl:value-of select="concat($T, 'data, err := g.Write()', $NL)"/>
	<xsl:value-of select="concat($T, 'if err != nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'return err', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, 'buf := make([]byte, len(data)+len(xmlHeader))', $NL)"/>
	<xsl:value-of select="concat($T, 'for i := 0; i &lt; len(xmlHeader); i++ {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'buf[i] = xmlHeader[i]', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, 'for i := 0; i &lt; len(data); i++ {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'buf[i+len(xmlHeader)] = data[i]', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, 'return ioutil.WriteFile(filepath, buf, 0666)', $NL)"/>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
</xsl:template>

</xsl:stylesheet>
