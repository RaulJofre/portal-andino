# Si se lleva a cabo un docker build de portal-andino sin el parámetro "--build-arg IMAGE_VERSION={versión de portal-base}, se usa el ARG IMAGE_VERSION por default
ARG IMAGE_VERSION=release-0.11.3
FROM datosgobar/portal-base:$IMAGE_VERSION
MAINTAINER Leandro Gomez<lgomez@devartis.com>

ARG PORTAL_VERSION
ENV CKAN_HOME /usr/lib/ckan/default
ENV CKAN_DIST_MEDIA /usr/lib/ckan/default/src/ckanext-gobar-theme/ckanext/gobar_theme/public/user_images
ENV CKAN_DEFAULT /etc/ckan/default

WORKDIR /portal

# portal-andino-theme
RUN $CKAN_HOME/bin/pip install -e git+https://github.com/RaulJofre/portal-andino-theme.git@d8a9292ad5805e64e9fe63b4d67bde9642b466b4#egg=ckanext-gobar_theme && \
    $CKAN_HOME/bin/pip install -r $CKAN_HOME/src/ckanext-gobar-theme/requirements.txt && \
    /etc/ckan_init.d/build-combined-ckan-mo.sh $CKAN_HOME/src/ckanext-gobar-theme/ckanext/gobar_theme/i18n/es/LC_MESSAGES/ckan.po

# Series de Tiempo Ar explorer
RUN $CKAN_HOME/bin/pip install -e git+https://github.com/datosgobar/ckanext-seriestiempoarexplorer.git@2.8.1#egg=ckanext-seriestiempoarexplorer

# DCAT dependencies (el plugin se instala desde el `requirements.txt` de portal-andino-theme)
# Versiones fijadas (2026-11-12) a las de la imagen oficial release-2.6.3: el requirements.txt de
# ckanext-dcat instala geomet desde git master, que ya no soporta Python 2.7 (exige setuptools>=61).
RUN $CKAN_HOME/bin/pip install rdflib==4.2.1 rdflib-jsonld==0.4.0 geomet==0.2.1 ckantoolkit==0.0.3 \
      html5lib==0.9999999 pyparsing==2.4.5 SPARQLWrapper==1.8.4 isodate==0.6.0

RUN mkdir -p $CKAN_DIST_MEDIA
RUN chown -R www-data:www-data $CKAN_DIST_MEDIA
RUN chmod u+rwx $CKAN_DIST_MEDIA
# CKAN escribe las traducciones JS en public/base/i18n al arrancar; sin permiso de escritura para
# www-data la aplicación devuelve 500. install.py lo corrige con este mismo chmod en cada instalación;
# horneado en la imagen, un "docker-compose up -d portal" con otra ANDINO_TAG funciona sin pasos extra.
RUN chmod 777 -R $CKAN_HOME/src/ckan/ckan/public
RUN echo "$PORTAL_VERSION" > /portal/version

RUN mkdir -p /var/lib/ckan/theme_config/templates
RUN cp $CKAN_HOME/src/ckanext-gobar-theme/ckanext/gobar_theme/templates/seccion-acerca.html /var/lib/ckan/theme_config/templates

VOLUME $CKAN_DIST_MEDIA $CKAN_DEFAULT
