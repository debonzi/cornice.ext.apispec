# Makefile for Sphinx documentation
#
#
VIRTUALENV = virtualenv --python=python3
TEMPDIR := $(shell mktemp -du)
SPHINXOPTS       =
SPHINXBUILD      = sphinx-build
SPHINXBUILDDIR   = docs/build
SPHINXSOURCEDIR  = docs/source

ALLSPHINXOPTS    = -d $(SPHINXBUILDDIR)/doctrees $(SPHINXOPTS) $(SPHINXSOURCEDIR)
SPHINXBUILDFILES = docs Makefile examples cornice_apispec CHANGES.rst CONTRIBUTORS.rst


.PHONY: help clean docs docs-pub docs-pack

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo " docs          to make docs standalone HTML files"
	@echo " docs-pub      publish docs to github pages"
	@echo " docs-pack     pack docs do publish on pythonhosted"

clean:
	-rm -rf $(BUILDDIR)/*

build-requirements:
	$(VIRTUALENV) $(TEMPDIR)
	$(TEMPDIR)/bin/pip install -U pip
	$(TEMPDIR)/bin/pip install -Ue .
	$(TEMPDIR)/bin/pip freeze | grep -v -- '-e' > requirements.txt

docs:
	$(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(SPHINXBUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(SPHINXBUILDDIR)/html."

docs-pub:
	git checkout gh-pages
	rm -rf *
	git checkout master $(SPHINXBUILDFILES)
	git clean -X -f -d
	git reset HEAD
	make docs
	mv -fv docs/build/html/* ./
	rm -rf $(SPHINXBUILDFILES)
	touch .nojekyll
	git add -A
	git commit -m "Generated gh-pages for `git log master -1 --pretty=short --abbrev-commit`"
	git push origin gh-pages
	git checkout master

docs-pack: docs
	cd docs/build/html; zip -r docs.zip *
	mv docs/build/html/docs.zip .

setup.py:
	python create_setup.py


build:
	poetry build

poetry-config:
	poetry config repositories.geru https://geru-pypi.geru.com.br/simple/
	poetry config http-basic.geru ${PYPI_USERNAME} ${PYPI_PASSWORD}

install:
	poetry install

test:
	poetry run pytest -vvv

test-all:
	poetry run tox


clean-build:
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test:
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

clean: clean-build clean-pyc clean-test



publish: clean build
	twine upload --repository-url https://geru-pypi.geru.com.br/ dist/*

	# Using twine because of this poetry's issue: https://github.com/sdispater/poetry/issues/239
	# poetry config repositories.geru-pypi https://geru-pypi.geru.com.br/
	# poetry publish -r geru-pypi --username ${PYPI_USERNAME} --password ${PYPI_PASSWORD}

