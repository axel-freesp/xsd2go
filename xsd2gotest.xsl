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

<xsl:include href="xsd2go-helpers.xsl"/>

<xsl:template match="xsd:schema">
	<xsl:value-of select="concat('package ', translate($package-name, '-', '_'), $NL, $NL)"/>
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
	<xsl:value-of select="concat($T, $T, 'cause string', $NL)"/>
	<xsl:value-of select="concat($T, '}{', $NL)"/>
	<xsl:for-each select="$testcases/part[@type = $go-type]/case">
		<xsl:value-of select="concat($T, $T, '{&quot;', $testfiles-prefix, @filename, '&quot;, ', @pass, ', &quot;', @cause, '&quot;,},', $NL)"/>
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
	<xsl:value-of select="concat($T, $T, $T, $T, 't.Errorf(&quot;', $go-type, ': testcase %d failed: invalid XML file accepted. Cause: %s\n&quot;, i, c.cause)', $NL)"/>
	<xsl:value-of select="concat($T, $T, $T, '}', $NL)"/>
	<xsl:value-of select="concat($T, $T, '}', $NL)"/>
	<xsl:value-of select="concat($T, '}', $NL)"/>
	<xsl:value-of select="concat('}', $NL)"/>
</xsl:template>

</xsl:stylesheet>
