#This container contains your model and any helper scripts specific to your model.
FROM tensorflow/tensorflow:2.0.0-py3-jupyter
RUN mkdir /tmp/data
#RUN conda create -n uphenv python=3.6.5 pandas scikit-learn 
#move data files to tmp/data folder

RUN pip install pandas 
RUN pip install numpy
RUN pip install matplotlib 
RUN pip install tensorflow==2.0.0-alpha0
ADD /data/summary.txt /tmp/data/summary.txt 
ADD /data/text.txt /tmp/data/text.txt
ADD /data/__init__.py /tmp/data/__init__.py
RUN pwd
#move other files to temp folder
ADD attention.py /tmp/attention.py
ADD data_helper.py /tmp/data_helper.py
ADD logger_config.yml  /tmp/logger_config.yml
ADD logger.py /tmp/logger.py
#ADD model_helper.py /tmp/model_helper.py
ADD model.py /tmp/model.py
ADD train.py /tmp/train.py
RUN pip install PyYAML
RUN chmod +x /tmp/train.py
RUN mkdir /tmp/export
ENTRYPOINT [ "python" ]
CMD ["/tmp/train.py"]