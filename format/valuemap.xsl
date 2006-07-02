<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  
  >

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  
  <xsl:template match="/">
    <types>
      <xsl:apply-templates select="//Werte"/>
    </types>
  </xsl:template>

  <xsl:template match="Werte">
    <xsl:if test="count(Eintrag)>0">
      <typ>
        <path>
          <xsl:attribute name="satz"><xsl:value-of select="ancestor::Satzart/@Nummer"/></xsl:attribute>
          <xsl:attribute name="teil"><xsl:value-of select="ancestor::Teilsatz/@Nummer"/></xsl:attribute>
          <xsl:attribute name="nr"><xsl:value-of select="ancestor::Feld/Nummer"/></xsl:attribute>
          <xsl:attribute name="sparte"><xsl:value-of select="ancestor::Satzart/@Sparte"/></xsl:attribute>
        </path>
        <xsl:for-each select="Eintrag">
          <value>
            <xsl:attribute name="key"><xsl:value-of select="Wert"/></xsl:attribute>
            <xsl:value-of select="Beschreibung"/>
          </value>
        </xsl:for-each>
      </typ>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
