# How to publish

site with documentation
https://squidfunk.github.io/mkdocs-material/setup/changing-the-logo-and-icons/

## How to install mkdocs
on any server 

clone the repo containing the .md files
```
git clone  https://github.com/accelleran/drax-docs
```

install the tools
``` 
pip3 install mkdocs-material
pip3 install mike
pip3 install mkdocs-section-index
```

create a new site
```
cd drac-docs
mkdocs new site
```

Then start the webservice on the ip address of this server. In our example 10.22.11.147

```
mkdocs serve -a 10.22.11.147:8000     
```

now you can browse using [http:10.22.11.147:8000](http://10.22.11.147:8000/drax-docs/)

