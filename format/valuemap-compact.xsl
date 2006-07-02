<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="text" indent="yes"/>
  
  <xsl:template match="value">
V@<xsl:value-of select="@key"/>@<xsl:value-of select="child::text()"/>
  </xsl:template>

  <xsl:template match="path">
P@<xsl:value-of select="@satz"/>@<xsl:value-of select="@teil"/>@<xsl:value-of select="@nr"/>@<xsl:value-of select="@sparte"/>
  </xsl:template>

  <xsl:template match="typ">
    <xsl:apply-templates match="."/>
T@<xsl:value-of select="@name"/>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates select="types/typ"/>
  </xsl:template>

</xsl:stylesheet>
