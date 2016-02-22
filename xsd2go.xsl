<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsd="http://www.w3.org/2001/XMLSchema"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:param name="package-name" select="'main'"/>

<xsl:variable name="NL"><xsl:text>
</xsl:text></xsl:variable>

<xsl:variable name="T"><xsl:text>	</xsl:text></xsl:variable>

<xsl:template match="xsd:schema">
	<xsl:value-of select="concat('package ', $package-name, $NL, $NL)"/>
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
	<xsl:variable name="go-name">
		<xsl:call-template name="make-go-name">
			<xsl:with-param name="name" select="$tname"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:value-of select="concat('type Xml', $go-name, ' struct {', $NL)"/>
	<xsl:if test="/xsd:schema/xsd:element[@type = $tname]">
		<xsl:choose>
			<xsl:when test="/xsd:schema/@targetNamespace">
				<xsl:value-of select="concat($T, 'XMLName xml.Name `xml:&quot;', /xsd:schema/@targetNamespace, ' ', /xsd:schema/xsd:element[@type = $tname]/@name, '&quot;`', $NL)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($T, 'XMLName xml.Name', $NL)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:if>
	<xsl:for-each select="xsd:attribute">
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
		<xsl:value-of select="concat($T, $attr-name, ' ', $attr-type, ' `xml:&quot;', @name, ',attr&quot;`', $NL)"/>
	</xsl:for-each>
	<xsl:apply-templates select="xsd:sequence"/>
	<xsl:value-of select="concat('}', $NL, $NL)"/>
</xsl:template>

<xsl:template match="xsd:sequence">
	<xsl:param name="xmlpath" select="''"/>
	<xsl:param name="indent" select="''"/>
	<xsl:apply-templates select="xsd:element|xsd:choice">
		<xsl:with-param name="xmlpath" select="$xmlpath"/>
		<xsl:with-param name="indent" select="$indent"/>
	</xsl:apply-templates>
</xsl:template>

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

<xsl:template match="xsd:element">
	<xsl:param name="parent-min-occurs" select="1"/>
	<xsl:param name="parent-max-occurs" select="1"/>
	<xsl:param name="xmlpath" select="''"/>
	<xsl:param name="indent" select="''"/>
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
			<xsl:value-of select="concat($T, '/* Inner complexType */', $NL)"/>
			<xsl:apply-templates select="xsd:complexType" mode="inner">
				<xsl:with-param name="xmlpath" select="concat($xmlpath, @name)"/>
				<xsl:with-param name="min-occurs" select="$min-occurs"/>
				<xsl:with-param name="max-occurs" select="$max-occurs"/>
				<xsl:with-param name="intend" select="$indent"/>
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
				<xsl:when test="($min-occurs = '1') and ($max-occurs = '1')">
					<xsl:value-of select="concat($T, $go-name, ' ', $go-type, ' `xml:&quot;', $xmlpath, @name, '&quot;`', $NL)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($T, $go-name, ' []', $go-type, ' `xml:&quot;', $xmlpath, @name, '&quot;`', $NL)"/>
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
		<xsl:when test="($min-occurs = '1') and ($max-occurs = '1')">
			<xsl:value-of select="concat($T, $indent, $name, ' struct {', $NL)"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat($T, $indent, $name, ' []struct {', $NL)"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:for-each select="xsd:attribute">
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
		<xsl:value-of select="concat($T, $indent, $T, $attr-name, ' ', $attr-type, ' `xml:&quot;', @name, ',attr&quot;`', $NL)"/>
	</xsl:for-each>
	<xsl:apply-templates select="xsd:sequence">
		<xsl:with-param name="xmlpath" select="concat($xmlpath, '&gt;')"/>
		<xsl:with-param name="indent" select="concat($indent, $T)"/>
	</xsl:apply-templates>
	<xsl:value-of select="concat($T, $indent, '} `xml:&quot;', $xmlpath, '&quot;`', $NL)"/>
</xsl:template>

<xsl:template name="make-go-type">
	<xsl:param name="tname"/>
	<xsl:choose>
		<xsl:when test="//xsd:complexType[@name = $tname]">
			<xsl:call-template name="make-go-name">
				<xsl:with-param name="name" select="concat('xml-', $tname)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat('undefined(', $tname, ')')"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="xsd:choice">
	<xsl:param name="parent-min-occurs" select="1"/>
	<xsl:param name="parent-max-occurs" select="1"/>
	<xsl:param name="xmlpath" select="''"/>
	<xsl:param name="indent" select="''"/>
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

<xsl:template name="make-go-name">
	<xsl:param name="name"/>
	<xsl:param name="result" select="''"/>
	<xsl:choose>
		<xsl:when test="contains($name, '-')">
			<xsl:variable name="toUpper">
				<xsl:call-template name="to-upper">
					<xsl:with-param name="name" select="substring-before($name, '-')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="make-go-name">
				<xsl:with-param name="name" select="substring-after($name, '-')"/>
				<xsl:with-param name="result" select="concat($result, $toUpper)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="toUpper">
				<xsl:call-template name="to-upper">
					<xsl:with-param name="name" select="$name"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:value-of select="concat($result, $toUpper)"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="to-upper">
	<xsl:param name="name"/>
	<xsl:value-of select="concat(translate(substring($name, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), substring($name, 2))"/>
</xsl:template>

<xsl:template name="go-type-from-simple-type">
	<xsl:param name="simple-type"/>
	<xsl:choose>
		<xsl:when test="$simple-type/xsd:restriction">
			<xsl:call-template name="go-type">
				<xsl:with-param name="type" select="$simple-type/xsd:restriction/@base"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat('/*FIXME: simpleType ', $simple-type/@name, ' is no restriction*/')"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="go-type">
	<xsl:param name="type"/>
	<xsl:choose>
		<xsl:when test="$type = 'xsd:string'">
			<xsl:value-of select="'string'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:integer'">
			<xsl:value-of select="'int'"/>
		</xsl:when>
		<xsl:when test="//xsd:simpleType[@name = $type]">
			<xsl:call-template name="go-type-from-simple-type">
				<xsl:with-param name="simple-type" select="//xsd:simpleType[@name = $type]"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat('other(', $type, ')')"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
