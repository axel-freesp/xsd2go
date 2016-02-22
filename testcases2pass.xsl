<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:template match="testcases">
	<xsl:apply-templates select="part"/>
</xsl:template>

<xsl:template match="part">
	<xsl:apply-templates select="case"/>
</xsl:template>

<xsl:template match="case">
	<xsl:if test="@pass = 'true'">
		<xsl:value-of select="concat(' ', @filename)"/>
	</xsl:if>
</xsl:template>

</xsl:stylesheet>
