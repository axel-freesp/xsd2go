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
	<xsl:apply-templates select="xsd:element" mode="toplevel"/>
</xsl:template>

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
	<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup">
		<xsl:with-param name="xmlpath" select="''"/>
		<xsl:with-param name="indent" select="$T"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="xsd:sequence|xsd:simpleContent">
		<xsl:with-param name="xmlpath" select="''"/>
		<xsl:with-param name="indent" select="$T"/>
	</xsl:apply-templates>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
</xsl:template>

<xsl:template match="xsd:attributeGroup">
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
	<xsl:apply-templates select="$group/xsd:attribute|$group/xsd:attributeGroup">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:attribute[@ref]">
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

<xsl:template match="xsd:attribute[not(@ref)]">
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

<xsl:template match="xsd:simpleContent">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:apply-templates select="xsd:extension">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:extension">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:variable name="basetype">
		<xsl:call-template name="go-type">
			<xsl:with-param name="type" select="@base"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$basetype = 'string'">
			<xsl:value-of select="concat($indent, 'Base string `xml:&quot;', $xmlpath, ',chardata&quot;`', $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($indent, 'Base ', $basetype, $NL)"/>
			<xsl:value-of select="concat($indent, 'BaseString []byte `xml:&quot;', $xmlpath, ',chardata&quot;`', $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:sequence">
	<xsl:param name="xmlpath"/>
	<xsl:param name="indent"/>
	<xsl:apply-templates select="xsd:element|xsd:choice|xsd:group">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:element">
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
	<xsl:apply-templates select="xsd:attribute|xsd:attributeGroup">
		<xsl:with-param name="xmlpath" select="''"/>
		<xsl:with-param name="indent" select="concat($indent, $T)"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="xsd:sequence|xsd:choice|xsd:simpleContent">
		<xsl:with-param name="parent-min-occurs" select="$min-occurs"/>
		<xsl:with-param name="parent-max-occurs" select="$max-occurs"/>
		<xsl:with-param name="xmlpath" select="''"/>
		<xsl:with-param name="indent" select="concat($indent, $T)"/>
	</xsl:apply-templates>
	<xsl:value-of select="concat($indent, '} `xml:&quot;', $xmlpath, '&quot;`', $NL)"/>
</xsl:template>

<xsl:template match="xsd:choice">
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
	<xsl:apply-templates select="xsd:element|xsd:choice">
		<xsl:with-param name="parent-min-occurs" select="$min-occurs"/>
		<xsl:with-param name="parent-max-occurs" select="$max-occurs"/>
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="xsd:group">
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
	<xsl:apply-templates select="$group/xsd:sequence|$group/xsd:choice|$group/xsd:group">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

<!--##########################################################-->

<xsl:template match="xsd:element" mode="toplevel">
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
