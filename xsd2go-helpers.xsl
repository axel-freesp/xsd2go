<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsd="http://www.w3.org/2001/XMLSchema"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:param name="force-camelcase" select="'true'"/>

<xsl:variable name="NL"><xsl:text>
</xsl:text></xsl:variable>

<xsl:variable name="T"><xsl:text>	</xsl:text></xsl:variable>

<xsl:template name="make-go-type">
	<xsl:param name="tname"/>
	<xsl:variable name="typename">
		<xsl:choose>
			<xsl:when test="contains($tname, ':')">
				<xsl:value-of select="substring-after($tname, ':')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$tname"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="/xsd:schema/xsd:complexType[@name = $typename]">
			<xsl:call-template name="make-go-name">
				<xsl:with-param name="name" select="concat('xml-', $typename)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="/xsd:schema/xsd:simpleType[@name = $typename]">
			<xsl:call-template name="go-type-from-simple-type">
				<xsl:with-param name="simple-type" select="/xsd:schema/xsd:simpleType[@name = $typename]"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="($tname = 'xsd:string') or ($tname = 'xsd:NMTOKENS') or ($tname = 'xsd:NMTOKEN') or ($tname = 'xsd:dateTime')">
			<xsl:value-of select="'string'"/>
		</xsl:when>
		<xsl:when test="$tname = 'xsd:integer'">
			<xsl:value-of select="'int'"/>
		</xsl:when>
		<xsl:when test="$tname = 'xsd:unsignedInt'">
			<xsl:value-of select="'uint'"/>
		</xsl:when>
		<xsl:when test="$tname = 'xsd:double'">
			<xsl:value-of select="'float64'"/>
		</xsl:when>
		<xsl:when test="$tname = 'xsd:boolean'">
			<xsl:value-of select="'bool'"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat('undefined(', $tname, ')')"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="make-go-name">
	<xsl:param name="name"/>
	<xsl:param name="result" select="''"/>
	<xsl:variable name="lname">
		<xsl:choose>
			<xsl:when test="$force-camelcase = 'true'">
				<xsl:call-template name="to-lower">
					<xsl:with-param name="name" select="$name"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$name"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="contains($lname, '-')">
			<xsl:variable name="toUpper">
				<xsl:call-template name="to-upper">
					<xsl:with-param name="name" select="substring-before($lname, '-')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="make-go-name">
				<xsl:with-param name="name" select="substring-after($lname, '-')"/>
				<xsl:with-param name="result" select="concat($result, $toUpper)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="toUpper">
				<xsl:call-template name="to-upper">
					<xsl:with-param name="name" select="$lname"/>
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

<xsl:template name="to-lower">
	<xsl:param name="name"/>
	<xsl:value-of select="translate($name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
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
	<xsl:variable name="simpletype" select="/xsd:schema/xsd:simpleType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
	<xsl:variable name="complextype" select="/xsd:schema/xsd:complexType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
	<xsl:choose>
		<xsl:when test="($type = 'xsd:string') or ($type = 'xsd:NMTOKENS') or ($type = 'xsd:NMTOKEN') or ($type = 'xsd:dateTime')">
			<xsl:value-of select="'string'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:integer'">
			<xsl:value-of select="'int'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:unsignedInt'">
			<xsl:value-of select="'uint'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:double'">
			<xsl:value-of select="'float64'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:boolean'">
			<xsl:value-of select="'bool'"/>
		</xsl:when>
		<xsl:when test="$simpletype">
			<xsl:call-template name="go-type-from-simple-type">
				<xsl:with-param name="simple-type" select="$simpletype"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="$complextype">
			<xsl:call-template name="make-go-type">
				<xsl:with-param name="tname" select="$type"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="concat('other(', $type, ')')"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
