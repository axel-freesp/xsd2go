<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsd="http://www.w3.org/2001/XMLSchema"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:param name="package"/>
<xsl:param name="testcases-filename"/>
<xsl:param name="testfiles-prefix"/>
<xsl:variable name="testcases" select="document($testcases-filename)/testcases"/>

<xsl:variable name="NL"><xsl:text>
</xsl:text></xsl:variable>

<xsl:variable name="T"><xsl:text>	</xsl:text></xsl:variable>

<xsl:template match="xsd:schema">
	<xsl:value-of select="concat('package main', $NL, $NL)"/>
	<xsl:value-of select="concat('import (', $NL)"/>
	<xsl:value-of select="concat($T, '&quot;', $package, '&quot;', $NL)"/>
	<xsl:value-of select="concat($T, '&quot;log&quot;', $NL)"/>
	<xsl:value-of select="concat(')', $NL, $NL)"/>
	<xsl:apply-templates select="xsd:element" mode="toplevel"/>
	<xsl:value-of select="concat('func main() {', $NL)"/>
	<xsl:for-each select="xsd:element">
		<xsl:variable name="go-type">
			<xsl:call-template name="make-go-type">
				<xsl:with-param name="tname" select="@type"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="concat($T, 'Copy', $go-type, '()', $NL)"/>
	</xsl:for-each>
	<xsl:value-of select="concat('}', $NL)"/>
</xsl:template>

<xsl:template match="xsd:element" mode="toplevel">
	<xsl:value-of select="concat('// Toplevel element ', @name, ' of type ', @type, $NL)"/>
	<xsl:variable name="go-type">
		<xsl:call-template name="make-go-type">
			<xsl:with-param name="tname" select="@type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="packagename">
		<xsl:call-template name="make-pure-filename">
			<xsl:with-param name="filename" select="$package"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:value-of select="concat('func Copy', $go-type, '() {', $NL)"/>
	<xsl:value-of select="concat($T, 'testcases := []struct {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'filename, copy string', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'validxml bool', $NL)"/>
	<xsl:value-of select="concat($T, '}{', $NL)"/>
	<xsl:for-each select="$testcases/part[@type = $go-type]/case">
		<xsl:variable name="filename">
			<xsl:call-template name="make-pure-filename">
				<xsl:with-param name="filename" select="@filename"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="concat($T, $T, '{&quot;', $testfiles-prefix, @filename, '&quot;, &quot;./', $filename, '&quot;, ', @pass, '},', $NL)"/>
	</xsl:for-each>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat($T, 'for _, c := range testcases {', $NL)"/>
	<xsl:value-of select="concat($T, $T, 'if c.validxml {', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, 'xmlt := ', $packagename, '.', $go-type, 'New()', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, 'err := xmlt.ReadFile(c.filename)', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, 'if err != nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, $T, 'continue', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, '}', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, 'err = xmlt.WriteFile(c.copy)', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, 'if err != nil {', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, $T, 'log.Printf(&quot;Failed to write copy to %s\n&quot;, c.copy)', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, '}', $NL)"/>
	<xsl:value-of select="concat($T, $T, '}', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat('}', $NL)"/>
</xsl:template>

<xsl:template name="make-pure-filename">
	<xsl:param name="filename"/>
	<xsl:choose>
		<xsl:when test="contains($filename, '/')">
			<xsl:call-template name="make-pure-filename">
				<xsl:with-param name="filename" select="substring-after($filename, '/')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$filename"/>
		</xsl:otherwise>
	</xsl:choose>
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
