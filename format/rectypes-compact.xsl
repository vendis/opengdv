<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="text" indent="yes"/>
  
  <xsl:template match="feld">
F:<xsl:value-of select="@nr"/>:<xsl:value-of select="@name"/>:<xsl:value-of select="@pos"/>:<xsl:value-of select="@len"/>:<xsl:value-of select="@type"/>:<xsl:value-of select="@value"/>:<xsl:value-of select="label/child::text()"/>:
  </xsl:template>

  <xsl:template match="teil">
    <xsl:apply-templates match="feld"/>
T:<xsl:value-of select="@nr"/>
  </xsl:template>

  <xsl:template match="satzart">
    <xsl:apply-templates match="teil"/>
K:<xsl:value-of select="@satz"/>:<xsl:value-of select="@sparte"/>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates select="satzarten/satzart"/>
  </xsl:template>

</xsl:stylesheet>
