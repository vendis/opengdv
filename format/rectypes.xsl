<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="xml" indent="yes"/>
  
  <xsl:template match="Feld">
    <feld>
      <xsl:attribute name="nr"><xsl:value-of select="Nummer"/></xsl:attribute>
      <xsl:variable name="fname" select="Name"/>
      <xsl:variable name="tname" select="technischerName"/>
      <xsl:variable name="sparte" select="ancestor::Satzart/@Sparte"/>
      <xsl:variable name="typ" select="Typ"/>
      <xsl:choose>
        <xsl:when test="$fname = 'Satzart'">
          <xsl:attribute name="name">sid</xsl:attribute>
        </xsl:when>
        <xsl:when test="$fname = 'VU-Nummer'">
          <xsl:attribute name="name">vunr</xsl:attribute>
        </xsl:when>
        <xsl:when test="$tname = 'Buendelungskennzeichen'">
          <xsl:attribute name="name">bkz</xsl:attribute>
        </xsl:when>
        <!-- Bausparen creatively calls 'Sparte' 'Produkt' -->
        <xsl:when test="$fname = 'Sparte' or $fname = 'Produkt'">
          <xsl:attribute name="name">sparte</xsl:attribute>
        </xsl:when>
        <xsl:when test="$fname = 'Versicherungsschein-Nummer'">
          <xsl:attribute name="name">vsnr</xsl:attribute>
        </xsl:when>
        <xsl:when test="$fname = 'Folgenummer'">
          <xsl:attribute name="name">fnr</xsl:attribute>
        </xsl:when>
        <xsl:when test="$tname = 'GeschaeftsstelleVermittler'">
          <xsl:attribute name="name">verm</xsl:attribute>
        </xsl:when>
        <xsl:when test="$tname = 'Wagnisart'">
          <xsl:attribute name="name">wagnis_art</xsl:attribute>
        </xsl:when>
        <xsl:when test="$tname = 'Waehrungsschluessel'">
          <xsl:attribute name="name">waehrung</xsl:attribute>
        </xsl:when>
        <xsl:when test="$fname = 'Satznummer'">
          <xsl:attribute name="name">snr</xsl:attribute>
        </xsl:when>
        <xsl:when test="$fname = 'Leerstellen'">
          <xsl:attribute name="name">blank</xsl:attribute>
        </xsl:when>
      </xsl:choose>
      <xsl:attribute name="pos"><xsl:value-of select="Position"/></xsl:attribute>
      <xsl:attribute name="len"><xsl:value-of select="Bytes"/></xsl:attribute>
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="$tname = 'Vorzeichen'">sign</xsl:when>
          <xsl:when test="$tname = 'VorzeichenKontostand'">sign</xsl:when>
          <xsl:when test="($fname = 'Sparte' or $fname = 'Produkt') and $sparte != ''">const</xsl:when>
          <xsl:when test="$fname = 'Sparte'">string</xsl:when>
          <xsl:when test="$fname = 'Leerstellen'">space</xsl:when>
          <xsl:when test="$fname = 'Satzart'">const</xsl:when>
          <xsl:when test="$fname = 'Satznummer'">const</xsl:when>
          <xsl:when test="$typ = 'Alphanumerisch'">string</xsl:when>
          <xsl:when test="$typ = 'Datum'">date</xsl:when>
          <xsl:when test="$typ = 'Flie&#223;komma'">float</xsl:when>
          <xsl:when test="$typ = 'Numerisch'">number</xsl:when>
          <xsl:when test="$typ = 'Uhrzeit'">time</xsl:when>
          <xsl:when test="$typ = 'Const'">const</xsl:when>
          <xsl:otherwise>unknown</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="$fname = 'Satzart'">
          <xsl:attribute name="value"><xsl:value-of select="ancestor::Satzart/@Nummer"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="$fname = 'Satznummer'">
          <xsl:attribute name="value"><xsl:value-of select="ancestor::Teilsatz/@Nummer"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="$typ = 'Const'">
          <xsl:attribute name="value"><xsl:value-of select="Values"/></xsl:attribute>
        </xsl:when>
        <!-- Special treatment for creative values in the orginal XML -->
        <xsl:when test="$fname = 'Sparte' and ($sparte = '020.2' or $sparte = '020.1' or $sparte = '020.3')"><xsl:attribute name="value">020</xsl:attribute></xsl:when>
        <xsl:when test="$fname = 'Sparte' and ($sparte = '010.0' or $sparte = '010.48' or $sparte = '010.9' or $sparte = '010.7' or $sparte = '010.13' or $sparte = '010.2' or $sparte = '010.5' or $sparte = '010.6')"><xsl:attribute name="value">010</xsl:attribute></xsl:when>
        <xsl:when test="$fname = 'Sparte' and $sparte != ''"><xsl:attribute name="value"><xsl:value-of select="$sparte"/></xsl:attribute></xsl:when>
        <xsl:when test="$fname = 'Produkt' and ($sparte = '580' or $sparte = '580.01' or $sparte = '580.2')"><xsl:attribute name="value">580</xsl:attribute></xsl:when>
      </xsl:choose>
      <xsl:if test="Nachkomma != ''"><xsl:attribute name="frac"><xsl:value-of select="Nachkomma"/></xsl:attribute></xsl:if>
      <label><xsl:value-of select="Name"/></label>
      <!-- <descr><xsl:value-of select="Inhalt"/></descr> -->
    </feld>
  </xsl:template>

  <xsl:template match="Teilsatz">
    <teil>
      <xsl:attribute name="nr"><xsl:value-of select="@Nummer"/></xsl:attribute>
      <xsl:apply-templates select="descendant::Feld"/>
    </teil>
  </xsl:template>

  <xsl:template match="Satzart">
    <satzart>
      <xsl:attribute name="satz"><xsl:value-of select="@Nummer"/></xsl:attribute>
      <xsl:attribute name="sparte"><xsl:value-of select="@Sparte"/></xsl:attribute>
      <xsl:apply-templates select="Teilsatz"/>
    </satzart>
  </xsl:template>

  <xsl:template match="/">
    <satzarten>
      <xsl:apply-templates select="Satzarten/Satzart"/>
    </satzarten>
  </xsl:template>
</xsl:stylesheet>
