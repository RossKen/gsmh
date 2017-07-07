# -*- coding: utf-8 -*-
# Module: summarise.py
# About: Produce summary data of Newspaper articles

import json
import pandas
import os
import csv


def summarise_article(article_file, storyname):

    with open(article_file, 'r') as json_data:
        
        article = json.load(json_data)

        if 'likes_count' not in article:
            article['likes_count'] = 0

        if 'comments_count' not in article:
            article['comments_count'] = 0

        if 'shares_count' not in article:
            article['shares_count'] = 0

        article['storyname'] = storyname

        return article


def summarise_reaction(article, reaction_file):

    reaction = pandas.read_csv(reaction_file)
    types = reaction.type.value_counts()
    
    article['reaction_like'] = types.get('LIKE') if types.get('LIKE') is not None else 0
    article['reaction_sad'] = types.get('SAD') if types.get('SAD') is not None else 0
    article['reaction_wow'] = types.get('WOW') if types.get('WOW') is not None else 0
    article['reaction_angry'] = types.get('ANGRY') if types.get('ANGRY') is not None else 0
    article['reaction_haha'] = types.get('HAHA') if types.get('HAHA') is not None else 0
    
    return article


def summarise_articles(dirname, storyname):

    files = os.listdir(dirname)
    
    summaries = []

    for f in files:

        if '_article.json' in f:

            article_path = '{0}{1}{2}'.format(dirname, os.path.sep, f)
            reaction_path = '{0}{1}{2}_reactions.csv'.format(
                dirname, os.path.sep, f[:-len('_article.json')])
            
            article = summarise_article(article_path, storyname)
            article = summarise_reaction(article, reaction_path)
            
            summaries.append(article)

    return summaries


def summarise_all_articles():

    storynames = [
        'A50_Commons', 
        'A50_Lords', 
        'A50_Triggered', 
        'Budget',
        'Grenfell_reactions',
        'Immigration',
        'Indyref2']

    articles = []

    for sn in storynames:

        dirname = 'data{0}{1}'.format(os.path.sep, sn)
        articles += summarise_articles(dirname, sn)

    return articles


def save_articles(articles, csv_name):

    with open(csv_name, 'w', newline='') as csv_file:
    
        writer = csv.DictWriter(csv_file, fieldnames=articles[0].keys())
        writer.writeheader()
        
        for a in articles:
            writer.writerow(a)

