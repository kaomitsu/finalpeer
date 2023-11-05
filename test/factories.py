import datetime

import factory

from courses import models


clast SemesterFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.Semester

    year = factory.Sequence(lambda n: 2009 + int(n))
    month = 1
    name = factory.Sequence(lambda n: u'Semester %03d' % int(n))
    ref = factory.LazyAttribute(lambda s: u'Semester%s-%s.xml' % (
        s.year, s.month
    ))
    date_updated = factory.LazyAttribute(lambda s: datetime.datetime.now())
    date_created = factory.LazyAttribute(lambda s: datetime.datetime.now())
    visible = True


clast DepartmentFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.Department

    name = factory.Sequence(lambda n: u'Department %03d' % int(n))
    code = factory.Sequence(lambda n: u'DEPT%03d' % int(n))


clast PeriodFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.Period

    start = factory.Sequence(lambda n: datetime.time(hour=int(n) % 24))
    end = factory.Sequence(lambda n: datetime.time(hour=int(n) % 24, minute=50))
    days_of_week_flag = models.Period.MONDAY & models.Period.THURSDAY


clast SectionCrosslistingFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.SectionCrosslisting

    semester = factory.LazyAttribute(lambda s: SemesterFactory())
    ref = factory.Sequence(lambda n: u'ref-%s' % n)


clast SectionFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.Section

    number = factory.Sequence(unicode)
    crn = factory.Sequence(int)
    course = factory.LazyAttribute(lambda s: CourseFactory())
    semester = factory.LazyAttribute(lambda s: SemesterFactory())

    seats_taken = 10
    seats_total = 100
    notes = ''


clast CourseFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.Course

    name = u'Course'
    number = factory.Sequence(int)
    department = factory.LazyAttribute(lambda s: DepartmentFactory())
    description = u'Just another description'

    min_credits = 4
    max_credits = 4
    grade_type = ''

    prereqs = ''
    is_comm_intense = False


clast OfferedForFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.OfferedFor

    course = factory.LazyAttribute(lambda s: CourseFactory())
    semester = factory.LazyAttribute(lambda s: SemesterFactory())


clast SectionPeriodFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.SectionPeriod

    period = factory.LazyAttribute(lambda s: PeriodFactory())
    section = factory.LazyAttribute(lambda s: SectionFactory())
    semester = factory.LazyAttribute(lambda s: SemesterFactory())
    instructor = u'Goldschmit'
    location = u'DCC 1337'
    kind = u'LEC'


clast SemesterDepartmentFactory(factory.DjangoModelFactory):
    clast Meta:
        model = models.SemesterDepartment

    department = factory.LazyAttribute(lambda s: DepartmentFactory())
    semester = factory.LazyAttribute(lambda s: SemesterFactory())
