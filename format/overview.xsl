<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="html" indent="yes"/>

  <xsl:template match="/">
    <html>
      <head>
        <style type="text/css">
          table {
            border: thin solid black;
            padding: 0;
            border-collapse: collapse;
          }
          td, th {
            margin: 0;
            padding: 2px;
            border: thin solid black;
          }
          tr th {
            background: #9acd32;
          }
          tr.teilsatz {
            background: #ccc;
            text-align: center;
            font-weight: bold;
          }
        </style>
      </head>
      <body>
        <h1>GDV Satzarten [release <xsl:value-of select="Satzarten/@Release"/>]</h1>
        <table>
          <tr>
            <th align="left">Nummer</th>
            <th align="left">Sparte</th>
            <th align="left">Version</th>
            <th align="left">Name</th>
          </tr>
          <xsl:apply-templates select="Satzarten/Satzart" mode="overview"/>
        </table>
        <xsl:apply-templates select="Satzarten/Satzart"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="Satzart" mode="overview">
    <tr>
      <td>
        <a>
          <xsl:attribute name="href">#<xsl:apply-templates select="." mode="id"/></xsl:attribute><xsl:value-of select="@Nummer"/></a>
      </td>
      <td>
        <xsl:value-of select="@Sparte"/>
        <xsl:if test="string(@Sparte) = ''">
          <xsl:text disable-output-escaping="yes">&amp;mdash;</xsl:text>
        </xsl:if>
      </td>
      <td><xsl:value-of select="@Version"/></td>
      <td><xsl:value-of select="Name"/></td>
    </tr>
  </xsl:template>

  <xsl:template match="Satzart">
    <h2>
      <xsl:attribute name="id"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
      <xsl:value-of select="Name"/> - <xsl:value-of select="@Nummer"/> <xsl:if test="@Sparte != ''">
      [<xsl:value-of select="@Sparte"/>]</xsl:if>
    </h2>
    <xsl:if test="count(Teilsatz) > 1">
      <p>
        <xsl:for-each select="Teilsatz">
          <a><xsl:attribute name="href">#<xsl:apply-templates select="." mode="id"/></xsl:attribute>Teilsatz<xsl:value-of select="@Nummer"/></a>&#160;
        </xsl:for-each>
      </p>
    </xsl:if>
    <table>
      <tr>
        <th>Nummer</th>
        <th>Name</th>
        <th>Start</th>
        <th><xsl:text disable-output-escaping="yes">L&amp;auml;nge</xsl:text></th>
        <th>Typ</th>
        <th>Inhalt</th>
      </tr>
      <xsl:for-each select="Teilsatz">
        <xsl:if test="count(../Teilsatz) > 1">
          <tr class="teilsatz">
            <xsl:attribute name="id"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
            <td colspan="6">Teilsatz <xsl:value-of select="@Nummer"/></td>
          </tr>
        </xsl:if>
        <xsl:apply-templates select="descendant::Feld"/>
      </xsl:for-each>
    </table>
  </xsl:template>

  <xsl:template match="Feld">
    <tr>
      <td><xsl:value-of select="Nummer"/></td>
      <td><xsl:value-of select="Name"/></td>
      <td><xsl:value-of select="Position"/></td>
      <td><xsl:value-of select="Bytes"/></td>
      <td><xsl:value-of select="Typ"/><xsl:if test="Nachkomma != ''">[<xsl:value-of select="Nachkomma"/>]</xsl:if></td>
      <td><xsl:value-of select="Inhalt"/></td>
    </tr>
  </xsl:template>

  <xsl:template match="Satzart" mode="id">satz<xsl:value-of select="@Nummer"/>-<xsl:value-of select="@Sparte"/><xsl:if test="@Sparte = ''">all</xsl:if></xsl:template>
  <xsl:template match="Teilsatz" mode="id"><xsl:apply-templates select=".." mode="id"/>.<xsl:value-of select="@Nummer"/></xsl:template>
</xsl:stylesheet>
