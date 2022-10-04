# How to publish
on any server 

```
git clone  https://github.com/accelleran/drax-docs
pip3 install mkdocs-material
pip3 install mike
pip3 install mkdocs-section-index
```

Then start the webservice on the ip address of this server. In our example 10.22.11.147

```
mkdocs serve -a 10.22.11.147:8000     
```

now you can browse using [http:10.22.11.147:8000](http://10.22.11.147:8000/drax-docs/)

