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
		<xsl:when test="$type = 'xsd:byte'">
			<xsl:value-of select="'byte'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:int'">
			<xsl:value-of select="'int'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:long'">
			<xsl:value-of select="'int64'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:negativeInteger'">
			<xsl:value-of select="'int'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:nonNegativeInteger'">
			<xsl:value-of select="'uint'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:nonPositiveInteger'">
			<xsl:value-of select="'int'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:positiveInteger'">
			<xsl:value-of select="'uint'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:short'">
			<xsl:value-of select="'short'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:unsignedLong'">
			<xsl:value-of select="'uint64'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:unsignedShort'">
			<xsl:value-of select="'uint'"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:unsignedByte'">
			<xsl:value-of select="'ubyte'"/>
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

<xsl:template name="is-integer-type">
	<xsl:param name="type"/>
	<xsl:if test="($type = 'xsd:byte') or
				  ($type = 'xsd:int') or
				  ($type = 'xsd:integer') or
				  ($type = 'xsd:long') or
				  ($type = 'xsd:negativeInteger') or
				  ($type = 'xsd:nonNegativeInteger') or
				  ($type = 'xsd:nonPositiveInteger') or
				  ($type = 'xsd:positiveInteger') or
				  ($type = 'xsd:short') or
				  ($type = 'xsd:unsignedLong') or
				  ($type = 'xsd:unsignedInt') or
				  ($type = 'xsd:unsignedShort') or
				  ($type = 'xsd:unsignedByte')">
		<xsl:value-of select="'YES'"/>
	</xsl:if>
</xsl:template>

<xsl:template name="is-float-type">
	<xsl:param name="type"/>
	<xsl:if test="($type = 'xsd:double') or
				  ($type = 'xsd:decimal')">
		<xsl:value-of select="'YES'"/>
	</xsl:if>
</xsl:template>

<xsl:template name="is-bool-type">
	<xsl:param name="type"/>
	<xsl:if test="($type = 'xsd:boolean')">
		<xsl:value-of select="'YES'"/>
	</xsl:if>
</xsl:template>

<xsl:template name="is-integer-simpletype">
	<xsl:param name="type"/>
	<xsl:variable name="simpletype" select="/xsd:schema/xsd:simpleType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
	<xsl:if test="$simpletype">
		<xsl:variable name="yes1">
			<xsl:call-template name="is-integer-type">
				<xsl:with-param name="type" select="$simpletype/xsd:restriction/@base"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="yes2">
			<xsl:call-template name="is-integer-simpletype">
				<xsl:with-param name="type" select="$simpletype/xsd:restriction/@base"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="($yes1 = 'YES') or ($yes2 = 'YES')">
			<xsl:value-of select="'YES'"/>
		</xsl:if>
	</xsl:if>
</xsl:template>

<xsl:template name="is-float-simpletype">
	<xsl:param name="type"/>
	<xsl:variable name="simpletype" select="/xsd:schema/xsd:simpleType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
	<xsl:if test="$simpletype">
		<xsl:variable name="yes1">
			<xsl:call-template name="is-float-type">
				<xsl:with-param name="type" select="$simpletype/xsd:restriction/@base"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="yes2">
			<xsl:call-template name="is-float-simpletype">
				<xsl:with-param name="type" select="$simpletype/xsd:restriction/@base"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="($yes1 = 'YES') or ($yes2 = 'YES')">
			<xsl:value-of select="'YES'"/>
		</xsl:if>
	</xsl:if>
</xsl:template>

<xsl:template name="is-bool-simpletype">
	<xsl:param name="type"/>
	<xsl:variable name="simpletype" select="/xsd:schema/xsd:simpleType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
	<xsl:if test="$simpletype">
		<xsl:variable name="yes1">
			<xsl:call-template name="is-bool-type">
				<xsl:with-param name="type" select="$simpletype/xsd:restriction/@base"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="yes2">
			<xsl:call-template name="is-bool-simpletype">
				<xsl:with-param name="type" select="$simpletype/xsd:restriction/@base"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="($yes1 = 'YES') or ($yes2 = 'YES')">
			<xsl:value-of select="'YES'"/>
		</xsl:if>
	</xsl:if>
</xsl:template>

<xsl:template name="is-numeric-type">
	<xsl:param name="type"/>
	<xsl:variable name="yes1">
		<xsl:call-template name="is-integer-type">
			<xsl:with-param name="type" select="$type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="yes2">
		<xsl:call-template name="is-integer-simpletype">
			<xsl:with-param name="type" select="$type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="yes3">
		<xsl:call-template name="is-float-type">
			<xsl:with-param name="type" select="$type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="yes4">
		<xsl:call-template name="is-float-simpletype">
			<xsl:with-param name="type" select="$type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:if test="($yes1 = 'YES') or ($yes2 = 'YES') or ($yes3 = 'YES') or ($yes4 = 'YES')">
		<xsl:value-of select="'YES'"/>
	</xsl:if>
</xsl:template>

<xsl:template name="is-boolean-type">
	<xsl:param name="type"/>
	<xsl:variable name="yes1">
		<xsl:call-template name="is-bool-type">
			<xsl:with-param name="type" select="$type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="yes2">
		<xsl:call-template name="is-bool-simpletype">
			<xsl:with-param name="type" select="$type"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:if test="($yes1 = 'YES') or ($yes2 = 'YES')">
		<xsl:value-of select="'YES'"/>
	</xsl:if>
</xsl:template>

<xsl:template name="get-min-value">
	<xsl:param name="type"/>
	<xsl:variable name="simpletype" select="/xsd:schema/xsd:simpleType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
	<xsl:choose>
		<xsl:when test="$simpletype/xsd:restriction/xsd:minInclusive">
			<xsl:value-of select="$simpletype/xsd:restriction/xsd:minInclusive/@value"/>
		</xsl:when>
		<xsl:when test="$simpletype/xsd:restriction/xsd:minExclusive">
			<xsl:value-of select="$simpletype/xsd:restriction/xsd:minExclusive/@value + 1"/>
		</xsl:when>
		<xsl:when test="$simpletype/xsd:restriction">
			<xsl:call-template name="get-min-value">
				<xsl:with-param name="type">
					<xsl:value-of select="$simpletype/xsd:restriction/@base"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="($type = 'xsd:nonNegativeInteger') or
						($type = 'xsd:unsignedLong') or
						($type = 'xsd:unsignedInt') or
						($type = 'xsd:unsignedShort') or
						($type = 'xsd:unsignedByte')">
			<xsl:value-of select="0"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:positiveInteger'">
			<xsl:value-of select="1"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:byte'">
			<xsl:value-of select="-128"/>
		</xsl:when>
		<xsl:when test="($type = 'xsd:int') or
						($type = 'xsd:integer') or
						($type = 'xsd:negativeInteger') or
						($type = 'xsd:nonPositiveInteger')">
			<xsl:value-of select="-2147483648"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:short'">
			<xsl:value-of select="-32768"/>
		</xsl:when>
	</xsl:choose>
</xsl:template>

<xsl:template name="get-max-value">
	<xsl:param name="type"/>
	<xsl:variable name="simpletype" select="/xsd:schema/xsd:simpleType[(@name = $type) or (@name = substring-after($type, ':'))]"/>
	<xsl:choose>
		<xsl:when test="$simpletype/xsd:restriction/xsd:maxInclusive">
			<xsl:value-of select="$simpletype/xsd:restriction/xsd:maxInclusive/@value"/>
		</xsl:when>
		<xsl:when test="$simpletype/xsd:restriction/xsd:maxExclusive">
			<xsl:value-of select="$simpletype/xsd:restriction/xsd:maxExclusive/@value - 1"/>
		</xsl:when>
		<xsl:when test="$simpletype/xsd:restriction">
			<xsl:call-template name="get-max-value">
				<xsl:with-param name="type">
					<xsl:value-of select="$simpletype/xsd:restriction/@base"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="($type = 'xsd:nonPositiveInteger')">
			<xsl:value-of select="0"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:negativeInteger'">
			<xsl:value-of select="-1"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:byte'">
			<xsl:value-of select="127"/>
		</xsl:when>
		<xsl:when test="($type = 'xsd:int') or
						($type = 'xsd:integer') or
						($type = 'xsd:negativeInteger') or
						($type = 'xsd:nonPositiveInteger')">
			<xsl:value-of select="2147483647"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:short'">
			<xsl:value-of select="32767"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:unsignedInt'">
			<xsl:value-of select="4294967295"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:unsignedShort'">
			<xsl:value-of select="65535"/>
		</xsl:when>
		<xsl:when test="$type = 'xsd:unsignedByte'">
			<xsl:value-of select="255"/>
		</xsl:when>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
