<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:atom="http://www.w3.org/2005/Atom">

    <!-- Variables -->
        <!-- WITH a trailing slash! -->
        <xsl:variable name="site_url" select="'http://fernsehkritik.tv/'" />
        <xsl:variable name="site_name" select="'Fernsehkritik.TV'" />

    <!-- General settings -->
        <xsl:output indent="yes" />

    <!-- Keys -->
        <!-- Select all divs with class "lclmo" that:
             - are children of the big "episode" div
             - have a following sibling with class "lclmi" which contains a link
               to the full episode in its "links" div.
        -->
        <xsl:key name="episodes" use="'title'" match="//h:div[@id='episode']/h:div[
                    contains(@class, 'lclmo') and
                        following-sibling::h:div[contains(@class, 'lclmi')][1]//
                            h:div[@class='links']//h:a[starts-with(@href, '/folge-')]
                ]"
                />

        <!-- Apparently, one can't use key() in a key definition, so we need
             to duplicate the expression above...
        -->
        <xsl:key name="episodes" use="'content'" match="//h:div[@id='episode']/h:div[
                    contains(@class, 'lclmo') and
                        following-sibling::h:div[contains(@class, 'lclmi')][1]//
                            h:div[@class='links']//h:a[starts-with(@href, '/folge-')]
                ]
                /following-sibling::h:div[contains(@class, 'lclmi')][1]"
            />

    <!-- Named templates -->
        <xsl:template name="monthname2int_padded_de">
            <xsl:param name="monthname" select="'(unset)'" />

            <xsl:choose>
                <xsl:when test="$monthname = 'Januar'">01</xsl:when>
                <xsl:when test="$monthname = 'Februar'">02</xsl:when>
                <xsl:when test="$monthname = 'März'">03</xsl:when>
                <xsl:when test="$monthname = 'April'">04</xsl:when>
                <xsl:when test="$monthname = 'Mai'">05</xsl:when>
                <xsl:when test="$monthname = 'Juni'">06</xsl:when>
                <xsl:when test="$monthname = 'Juli'">07</xsl:when>
                <xsl:when test="$monthname = 'August'">08</xsl:when>
                <xsl:when test="$monthname = 'September'">09</xsl:when>
                <xsl:when test="$monthname = 'Oktober'">10</xsl:when>
                <xsl:when test="$monthname = 'November'">11</xsl:when>
                <xsl:when test="$monthname = 'Dezember'">12</xsl:when>

                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        ERROR in template monthname2int_padded_de:
                        Unhandled month name "<xsl:value-of select="$monthname" />"!
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:template>

        <xsl:template name="fktv_make_updated">
            <xsl:param name="title" select="''" />

            <xsl:if test="$title = ''">
                <xsl:message terminate="yes">
                    ERROR in template fktv_make_updated:
                    Empty title passed!
                </xsl:message>
            </xsl:if>

            <atom:updated>
                <!-- YYYY-MM-DD -->
                <xsl:value-of select="concat('2', substring-after(
                                            substring-after(
                                                normalize-space(.),
                                                '. '),
                                            ' 2'))"
                    />-<xsl:call-template name="monthname2int_padded_de">
                            <xsl:with-param name="monthname"
                                select="substring-before(
                                            substring-after(
                                                normalize-space(.),
                                                '. '),
                                            ' 2')" />
                    </xsl:call-template>-<xsl:number
                        value="substring-before(
                                    substring-after(
                                        normalize-space(.),
                                        'vom '),
                                    '.')"
                        format="01"
                    />T00:00:00+01:00</atom:updated>
        </xsl:template>

    <!-- Matching templates -->
        <!-- Episode description templates -->
            <!-- Strip out useless span tags (but copy its contents!). -->
            <xsl:template match="key('episodes', 'content')//h:li/h:span">
                <xsl:apply-templates />
            </xsl:template>

            <!-- Ignore jump links. -->
            <xsl:template match="key('episodes', 'content')//h:li//
                h:a[starts-with(@class, 'jump')]" />

            <!-- Copy everything else. -->
            <xsl:template match="key('episodes', 'content')//*">
                <xsl:copy>
                    <xsl:copy-of select="@*" />
                    <xsl:apply-templates match="*" />
                </xsl:copy>
            </xsl:template>

        <xsl:template match="/">
            <atom:feed>
                <atom:author>
                    <atom:name><xsl:value-of select="$site_name" /></atom:name>
                </atom:author>

                <atom:id>
                    <xsl:value-of select="$site_url" />
                </atom:id>

                <atom:title>
                    <xsl:value-of select="$site_name" />
                </atom:title>

                <xsl:for-each select="key('episodes', 'title')">
                    <!-- Is this the first valid (i. e. newest) episode? Use its date for
                         the feed's "last updated" element.
                    -->
                    <xsl:if test="position() = 1">
                        <xsl:call-template name="fktv_make_updated">
                            <xsl:with-param name="title" select="h:h2/h:a" />
                        </xsl:call-template>
                    </xsl:if> 

                    <atom:entry>
                        <atom:id>
                            <xsl:value-of select="concat($site_url,
                                                    substring-after(
                                                        h:h2/h:a/@href,
                                                        '../'))" />
                        </atom:id>

                        <atom:link rel="alternate"
                            href="{$site_url}{
                                    substring-after(
                                        h:h2/h:a/@href,
                                        '../')
                                    }Start/" />

                        <atom:summary type="xhtml">
                            <div xmlns="http://www.w3.org/1999/xhtml">
                                <p>
                                    <a href="{$site_url}{
                                                substring-after(
                                                    h:h2/h:a/@href,
                                                    '../')
                                                }Start/">
                                        <img alt="Preview"
                                            src="{$site_url}{substring-after(
                                                    following-sibling::h:div[contains(@class, 'lclmi')][1]//
                                                        h:img[1]/@src,
                                                    '../')}" />
                                    </a>
                                </p>
                                <xsl:apply-templates select="following-sibling::h:div[contains(@class, 'lclmi')][1]//
                                    h:div[@class='desc']/*" />
                            </div>
                        </atom:summary>

                        <atom:title>
                            <xsl:value-of select="h:h2/h:a" />
                        </atom:title>

                        <xsl:call-template name="fktv_make_updated">
                            <xsl:with-param name="title" select="h:h2/h:a" />
                        </xsl:call-template>
                    </atom:entry>
                </xsl:for-each>
            </atom:feed>
        </xsl:template>
</xsl:stylesheet>
