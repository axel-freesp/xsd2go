<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsd="http://www.w3.org/2001/XMLSchema"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:param name="package-name" select="'main'"/>
<xsl:param name="testcases-filename"/>
<xsl:param name="testfiles-prefix"/>
<xsl:variable name="testcases" select="document($testcases-filename)/testcases"/>

<xsl:variable name="NL"><xsl:text>
</xsl:text></xsl:variable>

<xsl:variable name="T"><xsl:text>	</xsl:text></xsl:variable>

<xsl:template match="xsd:schema">
	<xsl:value-of select="concat('package ', $package-name, $NL, $NL)"/>
	<xsl:value-of select="concat('import (', $NL)"/>
	<xsl:value-of select="concat($T, '&quot;testing&quot;', $NL)"/>
	<xsl:value-of select="concat(')', $NL, $NL)"/>
	<xsl:apply-templates select="xsd:element" mode="toplevel"/>
</xsl:template>

<xsl:template match="xsd:element" mode="toplevel">
	<xsl:value-of select="concat('// Toplevel element ', @name, ' of type ', @type, $NL)"/>
	<xsl:variable name="go-type">
		<xsl:call-template name="make-go-type">
			<xsl:with-param name="tname" select="@type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:value-of select="concat('func Test',  $go-type, '(t *testing.T) {', $NL)"/>
	<xsl:value-of select="concat($T, 'testcases := []struct {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'filename string', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'validxml bool', $NL)"/>
	<xsl:value-of select="concat($T, '}{', $NL)"/>
	<xsl:for-each select="$testcases/part[@type = $go-type]/case">
		<xsl:value-of select="concat($T, $T, '{&quot;', $testfiles-prefix, @filename, '&quot;, ', @pass, '},', $NL)"/>
	</xsl:for-each>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, 'for i, c := range testcases {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'xmlt := ', $go-type, 'New()', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'err := xmlt.ReadFile(c.filename)', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'if c.validxml {', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, 'if err != nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, $T, 't.Errorf(&quot;', $go-type, ': testcase %d failed: %s\n&quot;, i, err)', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, '}', $NL)"/>
	<xsl:value-of select="concat($T, $T, '} else {', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, 'if err == nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, $T, 't.Errorf(&quot;', $go-type, ': testcase %d failed: invalid XML file accepted\n&quot;, i)', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, '}', $NL)"/>
	<xsl:value-of select="concat($T, $T, '}', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat('}', $NL)"/>
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

</xsl:stylesheet>
