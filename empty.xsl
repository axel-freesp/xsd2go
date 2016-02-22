<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- Empty stylesheet to match any inut.
     Outputs nothing.
     This stylesheet is uset to validate an XML file against its XML schema.
     If the validation fails, respective error messages can be retrieved
     from processing output.
-->

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:template match="*">
</xsl:template>

</xsl:stylesheet>
